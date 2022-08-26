// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./CrowdHelpStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrowdHelp is Ownable, ERC20 {
    using SafeMath for uint256;

    uint256 totalDeposits;
    uint256 currentCrowdNFTId;

    // Crowd help storage contract
    CrowdHelpStorage _crowdHelpStorage;

    enum CrowdRequestStatus {
        Start,
        Completed
    }

    // Contract owner
    address payable public admin;

    constructor(uint256 _quantity) ERC20("CrowdHelp Token", "CDHT") {
        admin = payable(msg.sender);
        address _to = address(this);
        _mint(_to, _quantity);
    }

    // Create request event
    event CreateRequestEvent(uint256 date, string title, address indexed owner);

    // Donate help event
    event DonateHelpEvent(
        uint256 date,
        uint256 requestId,
        address indexed donor
    );

    // withdraw event
    event WithdrawEvent(uint256 date, uint256 requestId, address indexed owner);

    // Create request for user
    function createCrowdRequest(
        string calldata title,
        string calldata description,
        uint256 amountNeeded,
        address owner
    ) external {
        require(amountNeeded > 0, "Amount Needed Can't Be Zero");

        _crowdHelpStorage.createRequest(
            title,
            description,
            amountNeeded,
            owner
        );

        emit CreateRequestEvent(block.timestamp, title, owner);
    }

    // Donate help to crowd help request
    function donateHelpToRequest(uint256 requestId, uint256 amount)
        public
        payable
    {
        require(amount > 0, "Donate Amount Can't Be Zero");

        uint256 currentRequestId = _crowdHelpStorage.getCurrentRequestId();

        //  Check if the request ID is valid
        require(
            requestId > 0 && requestId <= currentRequestId,
            "Request ID must be within valid Crowd Request range"
        );

        //  Get the request info

        (
            string memory title,
            string memory description,
            uint256 amountNeeded,
            uint256 totalRaisedAmount,
            uint256 totalWithdrawnAmount,
            uint256 status,
            address owner
        ) = _crowdHelpStorage.getRequestInfo(requestId);

        // If request is completed, bounce back
        require(
            status == uint256(CrowdRequestStatus.Completed),
            "Crowd request help is completed"
        );

        // Transfer amount to contract address
        payable(address(this)).transfer(amount);

        // Increasr total deposit into the contract address
        totalDeposits = totalDeposits.add(amount);

        //  Increase total amount raised
        uint256 updatedTotalAmountRaised = _crowdHelpStorage
            .increaseTotalAmountRaised(requestId, amount);

        // Updated request status to completed if total amount raised is eqaul to amount Needed
        if (updatedTotalAmountRaised == amountNeeded) {
            _crowdHelpStorage.updateRequestStatus(
                requestId,
                uint256(CrowdRequestStatus.Completed)
            );
        }

        // Reward donor

        uint256 reward = (amount.div(amountNeeded)).mul(100);

        _rewardDonor(msg.sender, reward);

        // Add donor to list
        _crowdHelpStorage.createDonor(requestId, msg.sender, amount);

        emit DonateHelpEvent(block.timestamp, requestId, msg.sender);
    }

    // Donate help to crowd help request
    function withdrawFromRequest(uint256 requestId, uint256 amount) external {
        require(amount > 0, "Withdraw Amount Can't Be Zero");

        uint256 currentRequestId = _crowdHelpStorage.getCurrentRequestId();

        //  Check if the request ID is valid
        require(
            requestId > 0 && requestId <= currentRequestId,
            "Request ID must be within valid Crowd Request range"
        );

        //  Get the Request info

        (
            string memory title,
            string memory description,
            uint256 amountNeeded,
            uint256 totalRaisedAmount,
            uint256 totalWithdrawnAmount,
            uint256 status,
            address owner
        ) = _crowdHelpStorage.getRequestInfo(requestId);

        //  Check user is the request owner
        require(
            owner != msg.sender,
            "You dont have access to withdraw this fund"
        );

        // If totalRaisedAmount is 0, bounce back
        require(
            totalRaisedAmount == 0,
            "Unable to proceed for withdraw, no amount raise yet"
        );

        require(
            totalWithdrawnAmount == totalRaisedAmount,
            "Insufficient fund, wait for more raise before you can withdraw"
        );

        // Transfer amount to withdraw from contract address to request owner
        payable(owner).transfer(amount);

        //  Increase total amount withdraw
        _crowdHelpStorage.increaseTotalWithdrawAmount(requestId, amount);

        emit WithdrawEvent(block.timestamp, requestId, owner);
    }

    // Transfer Crowd Help Token to Donor as reward for giving help
    function _rewardDonor(address recipient, uint256 reward) internal {
        currentCrowdNFTId++;

        _transfer(address(this), recipient, reward);
    }
}
