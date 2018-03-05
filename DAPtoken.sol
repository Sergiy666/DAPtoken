pragma solidity ^0.4.10;
import "./StandardToken.sol";
import "./SafeMath.sol";

contract DAPtoken is StandardToken, SafeMath {

    // metadata
    string public constant name = "dApp Builder Token";
    string public constant symbol = "DAP";
    uint256 public constant decimals = 4;
    string public version = "1.0";

    //addresses
    address public ethFundDeposit; // адрес, куда поступит собранный эфир после окончания ICO
    address public dapFundDeposit; // адрес, куда поступят DAP-токены, выпущенные в момент создания контракта (dapInitial) и оставшиеся нераспроданные токены

    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public constant dapTotal = 2 * (10**9) * 10**decimals;   // всего выпускается 2 000 000 000 токенов
    uint256 public constant dapInitial = 50 * (10**6) * 10**decimals; //Количество DAP-токенов для первоначального выпуска, здесь токены, которые нужно будет выплатить покупателям с пресейла и токены для бонусной программы
    uint256 public constant tokenExchangeRate = 21525; // 21525 DAP tokens per 1 ETH
    uint256 public constant tokenCreationCap =  700 * (10**9) * 10**decimals; //Максимальное количество токенов, которое может быть распродано, взято из расчёта выделения 35% всех токенов на ICO

    // events
    event CreateDAP(address indexed _to, uint256 _value);

    // constructor
    function DAPtoken(address _ethFundDeposit, address _dapFundDeposit, uint256 _fundingStartBlock, uint256 _fundingEndBlock) {
      isFinalized = false;
      ethFundDeposit = _ethFundDeposit;
      dapFundDeposit = _dapFundDeposit;
      fundingStartBlock = _fundingStartBlock;
      fundingEndBlock = _fundingEndBlock;
      totalSupply = dapInitial;
      balances[dapFundDeposit] = dapInitial;
      CreateDAP(dapFundDeposit, dapInitial);
    }

    /// @dev Accepts ether and creates new DAP tokens.
    function createTokens() payable external {
      if (isFinalized) throw;
      if (block.number < fundingStartBlock) throw;
      if (block.number > fundingEndBlock) throw;
      if (msg.value == 0) throw;

      uint256 tokens = safeMult(msg.value, tokenExchangeRate); // check that we're not over totals
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

      // return money if something goes wrong
      if (tokenCreationCap < checkedSupply) throw;  // odd fractions won't be found

      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;
      CreateDAP(msg.sender, tokens);  // logs token creation
    }

    /// @dev Ends the funding period and sends the ETH home
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != ethFundDeposit) throw;
      if (block.number <= fundingEndBlock && totalSupply != tokenCreationCap) throw;
      
      isFinalized = true;
      
      uint256 tokens = safeSubtract(dapTotal, totalSupply);
      
      balances[dapFundDeposit] += tokens;
      CreateDAP(dapFundDeposit, tokens);  // logs token creation
      
      if(!ethFundDeposit.send(this.balance)) throw;
    }

}