pragma solidity >=0.4.22 <=0.8.19;

contract BankAccount {

    event Deposit(address indexed user, uint indexed accountId, uint value, uint timestamp);
    event WithdrawRequest(address indexed userm, uint indexed accountId, uint indexed withdrawId, uint amount, uint timestamp);
    event Withdraw(uint indexed withdrawId, uint timestamp);
    event AccountCreated(address[] owners, uint indexed id, uint timestamp);

}
 