// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CrowdHelpStorage {
    using SafeMath for uint256;

    uint256 currentRequestId;

    struct CrowdRequest {
        string title;
        string description;
        address owner;
        uint256 amountNeeded;
        uint256 totalRaisedAmount;
        uint256 totalWithdrawnAmount;
        CrowdRequestStatus status;
    }

    enum CrowdRequestStatus {
        Open,
        Completed
    }

    mapping(uint256 => CrowdRequest) crowdRequests;
    mapping(uint256 => mapping(address => uint256)) crowdRequestDonors;

    // Check if cycleId is valid
    modifier isRequestIdValid(uint256 requestId) {
        require(
            requestId != 0 && requestId <= currentRequestId,
            "Request ID must be within valid crowd help request range"
        );
        _;
    }

    // Create crowd help request
    function createRequest(
        string calldata title,
        string calldata description,
        uint256 amountNeeded,
        address owner
    ) external {
        currentRequestId.add(1);
        CrowdRequest storage request = crowdRequests[currentRequestId];
        request.title = title;
        request.description = description;
        request.owner = owner;
        request.status = CrowdRequestStatus.Open;
        request.amountNeeded = amountNeeded;
        request.totalWithdrawnAmount = 0;
        request.totalRaisedAmount = 0;
    }



    // Increase total amount raised in crowd help request
    function increaseTotalAmountRaised(uint256 requestId, uint256 amount)
        external
        isRequestIdValid(requestId)
        returns (uint256)
    {
        CrowdRequest storage request = crowdRequests[requestId];

        uint256 totalRaisedAmount = request.totalRaisedAmount.add(amount);

        request.totalRaisedAmount = totalRaisedAmount;

        return totalRaisedAmount;
    }

    // Increase total amount raised in crowd help request
    function increaseTotalWithdrawAmount(uint256 requestId, uint256 amount)
        external
        isRequestIdValid(requestId)
        returns (uint256)
    {
        CrowdRequest storage request = crowdRequests[requestId];

        uint256 totalWithdrawnAmount = request.totalWithdrawnAmount.add(amount);

        request.totalWithdrawnAmount = totalWithdrawnAmount;

        return totalWithdrawnAmount;
    }


    // Update Esusu Status
    function updateRequestStatus(uint256 requestId, uint256 status) external {
        CrowdRequest storage request = crowdRequests[requestId];

        request.status = CrowdRequestStatus(status);
    }

    // Add donor to request donor list
    function createDonor(
        uint256 requestId,
        address member,
        uint256 amount
    ) external {
        mapping(address => uint256) storage donor = crowdRequestDonors[
            requestId
        ];
        donor[member] = amount;
    }

    //View functions

    function getCurrentRequestId() external view returns (uint256) {
        return currentRequestId;
    }

    // Get crowd help request info
    function getRequestInfo(uint256 requestId)
        external
        view
        isRequestIdValid(requestId)
        returns (
            string memory title,
            string memory description,
            uint256 amountNeeded,
            uint256 totalRaisedAmount,
            uint256 totalWithdrawnAmount,
            uint256 status,
            address owner
        )
    {
        CrowdRequest memory request = crowdRequests[requestId];

        return (
            request.title,
            request.description,
            request.amountNeeded,
            request.totalRaisedAmount,
            request.totalWithdrawnAmount,
            uint256(request.status),
            request.owner
        );
    }

    // Get crowd request status
    function getRequestStatus(uint256 requestId)
        external
        view
        returns (uint256)
    {
        return uint256(crowdRequests[requestId].status);
    }

}
