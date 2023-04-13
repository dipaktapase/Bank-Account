pragma solidity >=0.4.22 <=0.8.19;

contract BankAccount {
    event Deposit(
        address indexed user,
        uint indexed accountId,
        uint value,
        uint timestamp
    );
    event WithdrawRequested(
        address indexed userm,
        uint indexed accountId,
        uint indexed withdrawId,
        uint amount,
        uint timestamp
    );
    event Withdraw(uint indexed withdrawId, uint timestamp);
    event AccountCreated(address[] owners, uint indexed id, uint timestamp);

    struct WithdrawRequest {
        address user;
        uint amount;
        uint approvals;
        mapping(address => bool) ownersApproved;
        bool approved;
    }

    struct Account {
        address[] owners;
        uint balance;
        mapping(uint => WithdrawRequest) withdrawRequest;
    }

    mapping(uint => Account) accounts;
    mapping(address => uint[]) userAccounts;

    uint nextAccountId;
    uint nextWithdrawId;

    modifier accountOwner(uint accountId) {
        bool isOwner;
        for (uint idx; idx < accounts[accountId].owners.length; idx++) {
            if (accounts[accountId].owners[idx] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "you are not an owner of this account");
        _;
    }

    modifier validOwners(address[] calldata owners) {
        require(owners.length + 1 <= 4, "maximum of 4 owners per account");
        for (uint i; i < owners.length; i++) {
            for (uint j = i + 1; j < owners.length; j++) {
                if (owners[i] == owners[j]) {
                    revert("no duplicate owners");
                }
            }
        }
        _;
    }

    modifier sufficientBalance(uint accountId, uint amount) {
        require(accounts[accountId].balance >= amount, "Insufficient balance");
        _;
    }

    modifier canApprove(uint accountId, uint withdrawId) {
        require(
            !accounts[accountId].withdrawRequest[withdrawId].approved,
            "this request is already approved"
        );
        require(
            accounts[accountId].withdrawRequest[withdrawId].user != msg.sender,
            "you cannot approve this request"
        );
        require(
            accounts[accountId].withdrawRequest[withdrawId].user != address(0),
            "this request does not exist"
        );
        require(
            !accounts[accountId].withdrawRequest[withdrawId].ownersApproved[
                msg.sender
            ],
            "you have already approved this request"
        );
        _;
    }

    modifier canWithdraw(uint accountId, uint withdrawId) {
        require(
            accounts[accountId].withdrawRequest[withdrawId].user == msg.sender,
            "you did not create this request"
        );
        require(
            accounts[accountId].withdrawRequest[withdrawId].approved,
            "this request is not approved"
        );
        _;
    }

    function deposit(uint accountId) external payable accountOwner(accountId) {
        accounts[accountId].balance += msg.value;
    }

    function createAccount(
        address[] calldata otherOwners
    ) external validOwners(otherOwners) {
        address[] memory owners = new address[](otherOwners.length + 1);
        owners[otherOwners.length] = msg.sender;

        uint id = nextAccountId;

        for (uint idx; idx < owners.length; idx++) {
            if (idx < owners.length - 1) {
                owners[idx] = otherOwners[idx];
            }

            if (userAccounts[owners[idx]].length > 2) {
                revert("Each user can have max of 3 accounts");
            }
            userAccounts[owners[idx]].push(id);
        }

        accounts[id].owners = owners;
        nextAccountId++;
        emit AccountCreated(owners, id, block.timestamp);
    }

    function requestWithdrawl(
        uint accountId,
        uint amount
    ) external accountOwner(accountId) sufficientBalance(accountId, amount) {
        uint id = nextWithdrawId;
        WithdrawRequest storage request = accounts[accountId].withdrawRequest[
            id
        ];
        request.user = msg.sender;
        request.amount = amount;
        nextWithdrawId++;
        emit WithdrawRequested(
            msg.sender,
            accountId,
            id,
            amount,
            block.timestamp
        );
    }

    function approveWithdrawl(
        uint accountId,
        uint withdrawId
    ) external accountOwner(accountId) canApprove(accountId, withdrawId) {
        WithdrawRequest storage request = accounts[accountId].withdrawRequest[
            withdrawId
        ];
        request.approvals++;
        request.ownersApproved[msg.sender] = true;

        if (request.approvals == accounts[accountId].owners.length - 1) {
            request.approved = true;
        }
    }

    function withdraw(
        uint accountId,
        uint withdrawId
    ) external canWithdraw(accountId, withdrawId) {
        uint amount = accounts[accountId].withdrawRequest[withdrawId].amount;
        require(accounts[accountId].balance >= amount, "Insufficient balance");

        accounts[accountId].balance -= amount;
        delete accounts[accountId].withdrawRequest[withdrawId];

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent);

        emit Withdraw(withdrawId, block.timestamp);
    }

    function getBalance(uint accountId) public view returns (uint) {
        return accounts[accountId].balance;
    }

    function getOwners(uint accountId) public view returns (address[] memory) {
        return accounts[accountId].owners;
    }

    function getApprovals(
        uint accountId,
        uint withdrawId
    ) public view returns (uint) {
        return accounts[accountId].withdrawRequest[withdrawId].approvals;
    }

    function getAccounts() public view returns (uint[] memory) {
        return userAccounts[msg.sender];
    }
}
