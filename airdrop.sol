/***********************//*
 * ------------------------
 * !
 * !  $SPP: AIRDROP CONTRACT
 * !
 * !    https://safepony.space/airdrop
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
    function _whitelist(address _addr) internal;
    function _unwhitelist(address _addr) internal;
    function totalSupply() public view returns (uint);
    function balanceOf(address account) public view  returns (uint balance);
    function transfer(address recipient, uint amount) public  returns (bool success);
    function transferFee(uint tokens) internal returns (bool success);
    function burn(uint amount) internal returns (bool success);
    function approve(address spender, uint amount) public returns (bool success);
    function _approve(address owner, address spender, uint256 amount) internal;
    function transferFrom(address sender, address recipient, uint amount) public returns (bool success);
    function allowance(address owner, address spender) public view returns (uint remaining);
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool);
    function _mint(address account, uint256 amount) internal;
    function _beforeTransfer(address from, address to, uint amount) internal returns (uint);
    function _settokendev(address dev) internal;
}

contract SafePonyProtocol is ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract SafePonyProtocolAIRDROP is Owned {
    using SafeMath for uint;

    uint256 public aSBlock; 
    uint256 public aEBlock; 
    uint256 public aCap;
    uint256 public aTot;
    uint256 public aAmt;
    
    address payable private devAddress;

    mapping(address => uint) claimed;
    
    SafePonyProtocol public safepony;
    
    constructor(SafePonyProtocol token, address payable dev) public {
        aSBlock = 1623988800;
        aEBlock = 1627689600;
        aAmt = 2000e18;
        aCap = 0;
        devAddress = dev;
        safepony = SafePonyProtocol(token);
    }
    function claimAirdrop() public returns (bool success){
        require(claimed[msg.sender] != 1);
        require(aSBlock <= now && now <= aEBlock);
        require(aTot < aCap || aCap == 0);
        aTot++;
        if(safepony.balanceOf(address(this)) >= aAmt) {
            claimed[msg.sender] = 1;
            safepony.transfer(msg.sender, aAmt);
            return true;
        } else {
            return false;
        }
    }
    function clearBNB() public {
        devAddress.transfer(address(this).balance);
    }
}