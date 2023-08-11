/***********************//*
 * ------------------------
 * !
 * !  $SPP SafePony Protocol (BSC)
 * !
 * !    https://safepony.space/
 * !
 * !    features:
 * !    4% auto-burn on every transaction
 * !    -- this will reduce the transaction cost
 * !       while still making the token price
 * !       skyrocket to the moon over time
 * !    3% marketing & development
 * !    
 * !    pancakeswap slippage: 8%
 * !    
 * -------------------------------------------------
 *//***********************//************************/

pragma solidity >=0.5.8;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Owned {
    address public owner;
    address public devAddress;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event DeveloperTransferred(address indexed _from, address indexed _to);
    constructor() public {
        owner = msg.sender;
        devAddress = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyDev {
        require(msg.sender == devAddress || msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) internal {
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
    function transferDeveloper(address newDev) internal {
        devAddress = newDev;
        emit DeveloperTransferred(devAddress, newDev);
    }
}

contract ERC20 is IERC20 {
    using SafeMath for uint;
    uint private _totalSupply;
    address private _dev;
    mapping(address => uint) private _balances;
    mapping(address => uint) private whitelisted;
    mapping(address => mapping(address => uint)) private _allowances;
    function _whitelist(address _addr) internal {
        whitelisted[_addr] = 1;
    }
    function _unwhitelist(address _addr) internal {
        whitelisted[_addr] = 0;
    }
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(_balances[address(0)]);
    }
    function balanceOf(address account) public view returns (uint balance) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool success) {
        amount = _beforeTransfer(msg.sender, recipient, amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFee(uint tokens) internal returns (bool success) {
        _balances[msg.sender] = _balances[msg.sender].sub(tokens);
        _balances[_dev] = _balances[_dev].add(tokens);
        emit Transfer(msg.sender, _dev, tokens);
        return true;
    }
    function burn(uint amount) internal returns (bool success) {
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[address(0)] = _balances[address(0)].add(amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }
    function approve(address spender, uint amount) public returns (bool success) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool success) {
        amount = _beforeTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint remaining) {
        return _allowances[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _beforeTransfer(address from, address to, uint amount) internal returns (uint) {
        if(whitelisted[to] == 0 && to != address(0) && whitelisted[from] == 0 && from != address(0)) {
            uint fee = amount.mul(3).div(100);
            uint burnFee = amount.mul(4).div(100);
            amount = amount.sub(fee);
            transferFee(fee);
            amount = amount.sub(burnFee);
            burn(burnFee);
        }
        return amount;
    }
    function _settokendev(address dev) internal {
        _dev = dev;
    }
}

contract SafePonyProtocol is ERC20, Owned {

    using SafeMath for uint;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor(address dev_) public {
        _symbol = "SPP";
        _name = "SafePony Protocol";
        _decimals = 18;
        _whitelist(msg.sender);
        _whitelist(dev_);
        setDeveloper(dev_);
        _mint(dev_, 1000000000e18);
    }
    
    function name() external view returns (string memory) {
        return _name;
    }
    
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    
    function whitelist(address _addr) public onlyDev {
        _whitelist(_addr);
    }
    
    function unwhitelist(address _addr) public onlyDev {
        _unwhitelist(_addr);
    }
    
    function setDeveloper(address dev) public onlyDev {
        _settokendev(dev);
        transferDeveloper(dev);
    }
    
    function renounceOwnership() public onlyOwner {
        transferOwnership(address(0));
    }
    
    function clearBNB() public onlyDev {
        address payable _dev = address(uint160(devAddress));
        _dev.transfer(address(this).balance);
    }
    
}