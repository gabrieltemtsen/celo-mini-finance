// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./IERC20.sol";

contract FusePay {
    string public companyCID;
    uint public companyID;
    address public admin;
    address[] public employees;
    mapping(address => uint256) public employeeSalaries;
    mapping(address => uint256) public employeeWalletBalances;

     enum LoanStatus {
         Pending,
          Approved, 
          Rejected
           }

   struct Loan {
        uint256 loanAmount;
        string reason;
        LoanStatus status;
    }
    mapping(address => Loan) public loans;

    constructor(string memory _companyCID, address _admin, uint _companyID) {
        companyCID = _companyCID;
        admin = _admin;
        companyID = _companyID;
    }

    modifier onlyOneEmployee(address _employeeAddress) {
        for (uint i = 0; i < employees.length; i++) {
            require(employees[i] != _employeeAddress, 'Employee already Exists');
        }
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Not an Admin');
        _;
    }

    function depositUSDC(uint256 amount) public onlyAdmin payable {
        IERC20 usdc = IERC20(0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1);
        
        require(usdc.transferFrom(admin, payable(address(this)), amount), 'Deposit failed');
    }

    function addEmployee(address _employeeAddress) public onlyOneEmployee(_employeeAddress) returns (bool) {
        employees.push(_employeeAddress);
        employeeWalletBalances[_employeeAddress] = 0; // Initialize wallet balance to zero
        return true;
    }

    function setEmployeeSalary(address _employeeAddress, uint256 _salary) public  returns (bool) {
        employeeSalaries[_employeeAddress] = _salary;
        return true;
    }

    function getEmployeeSalary(address _employeeAddress) public view returns (uint256) {
        return employeeSalaries[_employeeAddress];
    }

    function getEmployeeWalletBalance(address _employeeAddress) public view returns (uint256) {
        return employeeWalletBalances[_employeeAddress];
    }

    function getEmployees() public view returns (address[] memory) {
        return employees;
    }

    function getAdmin() public view returns (address) {
        return admin;
    }

    function addMonthlySalaries() public onlyAdmin {
        for (uint256 i = 0; i < employees.length; i++) {
            address employee = employees[i];
            uint256 salary = employeeSalaries[employee];
            employeeWalletBalances[employee] += salary;
        }
    }

      function withdrawSalary(uint256 _amount) public {
        address employee = msg.sender;
        uint256 balance = employeeWalletBalances[employee];
        require(balance > 0, 'No salary to withdraw');
        require(balance >= _amount, 'Amount exceeds balance');

        IERC20 usdc = IERC20(0x690000EF01deCE82d837B5fAa2719AE47b156697);
        require(usdc.transfer(employee, _amount), 'Transfer failed');
        uint256 newBal = employeeWalletBalances[employee] - _amount; 
        employeeWalletBalances[employee] = newBal;
        
    }
   function requestLoan(uint256 _amount, string memory _reason) public {
    require(loans[msg.sender].loanAmount == 0 || loans[msg.sender].status != LoanStatus.Pending, 'Cannot request a new loan while previous loan is pending');
    loans[msg.sender] = Loan(_amount, _reason, LoanStatus.Pending);
}
    function approveLoan(address _employeeAddress) public onlyAdmin {
        Loan storage loan = loans[_employeeAddress];
        require(loan.status == LoanStatus.Pending, 'Loan is not pending approval');

        loan.status = LoanStatus.Approved;

        uint256 amount = loan.loanAmount;
        address requester = _employeeAddress;
        address stablecoinAddress = 0x690000EF01deCE82d837B5fAa2719AE47b156697; //CUSD
        IERC20 stablecoin = IERC20(stablecoinAddress);
        require(stablecoin.transfer(requester, amount), 'Transfer of funds failed');
    }
    function rejectLoan(address _employeeAddress) public onlyAdmin {
        Loan storage loan = loans[_employeeAddress];
        require(loan.status == LoanStatus.Pending, 'Loan is not pending approval');

        loan.status = LoanStatus.Rejected;
    }
//     function getLoanRequests() public view returns ( address[] memory) {
//     return loans;
// }

    receive() external payable {
        // Handle the received Ether here
    }
}