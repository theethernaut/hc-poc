pragma solidity ^0.5.0;

import "./SafeMath.sol";

/*
 * A sample ERC20 token with mint and burn ability.
 */
contract Token {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  address private _owner;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  modifier onlyOwner() {
    require(msg.sender == _owner, "Ownable: caller is not the owner");
    _;
  }

  constructor() public {
    _owner = msg.sender;
  }

  /*
   * External functions.
   */

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowances[owner][spender];
  }

  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
    return true;
  }

  function mint(address to, uint256 value) public onlyOwner returns (bool) {
    _mint(to, value);
    return true;
  }

  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

  /*
   * Internal functions.
   */

  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0), "ERC20: transfer to the zero address");

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  function _approve(address owner, address spender, uint256 value) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function _mint(address account, uint256 value) internal {
    require(account != address(0), "ERC20: mint to the zero address");

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  function _burn(address account, uint256 value) internal {
    require(account != address(0), "ERC20: burn from the zero address");

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }
}
