pragma solidity ^0.4.19;

// ----------------------------------------------------------------------------
// SafeMath not included to reduce gas costs
// ----------------------------------------------------------------------------
// library SafeMath
// {
//     function add(uint a, uint b) internal pure returns (uint c)
//     {
//         c = a + b;
//         require(c >= a);
//     }
//     function sub(uint a, uint b) internal pure returns (uint c)
//     {
//         require(b <= a);
//         c = a - b;
//     }
//     function mul(uint a, uint b) internal pure returns (uint c)
//     {
//         c = a * b;
//         require(a == 0 || c / a == b);
//     }
//     function div(uint a, uint b) internal pure returns (uint c)
//     {
//         require(b > 0);
//         c = a / b;
//     }
// }

contract ERC20Interface
{
    function totalSupply() constant returns (uint supply) {}
    function balanceOf(address _owner) constant returns (uint balance) {}
    function transfer(address _to, uint _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {}
    function approve(address _spender, uint _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);    
}

contract RewardToken is ERC20Interface
{
    struct Account
    {
      uint balance;
      uint lastDividendPoints;
    }

    mapping(address=>Account) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
    uint totalDividendPoints;

    event RewardAdded(address sender, uint );

    function dividendsOwing(address account) internal returns(uint)
    {
      uint newDividendPoints = totalDividendPoints - balances[account].lastDividendPoints;
      return (balances[account].balance * newDividendPoints) / totalSupply;
    }

    modifier updateAccount(address account)
    {
      uint owing = dividendsOwing(account);
      if(owing > 0)
      {
        account.transfer(owing);
      }
      balances[account].lastDividendPoints = totalDividendPoints;
      _;
    }

    function disburse() internal
    {
      totalDividendPoints += msg.value;
      RewardAdded(msg.sender, msg.value);
    }

    function _transfer(address _from, address _to, uint _value) updateAccount(_to) updateAccount(msg.sender) internal returns (bool success)
    {
        require(_to != 0x0);
        require(balances[_from].balance >= _value);
        require(balances[_to].balance + _value > balances[_to].balance);
        balances[_from].balance -= _value;
        balances[_to].balance += _value;
        Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint _value) public returns (bool success)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success)
    {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint balance)
    {
        return balances[_owner].balance;
    }

    function approve(address _spender, uint _value) returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining)
    {
      return allowed[_owner][_spender];
    }
}

contract TestToken is RewardToken
{
    string public name;
    string public symbol;
    uint8 public decimals;
    address public coinStorage;
    address public creator;

    function TestToken(string tokenName, string tokenSymbol, uint8 _decimals, uint _totalSupplyinEther, address _coinStorage)
    {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = _decimals;
        balances[_coinStorage].balance = _totalSupplyinEther * 10 ** uint(18);
        totalSupply = _totalSupplyinEther * 10 ** uint(18);
        coinStorage = _coinStorage;
        creator = msg.sender;
    }

    function() payable
    {
        require(msg.value > 0);
        disburse();
    }

    function updateCreator(address _creator) external
    {
        require(msg.sender == creator);
        creator = _creator;
    }

    function updateCoinStorage(address _coinStorage) external
    {
        require(msg.sender == creator);
        coinStorage = _coinStorage;
    }

    function approveAndCall(address _spender, uint _value, bytes _extraData) returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint,address,bytes)"))), msg.sender, _value, this, _extraData))
            { throw; }
        return true;
    }
}
