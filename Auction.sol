pragma solidity ^0.4.8;

contract Auction {
    // static
    address public owner;
    uint public startBlock;
    uint public endBlock;
    string public NumContainer;
    string public Manufacturer;
    string public dateMade;
    string public partRepair;
    string public reqRepair;
    string public region;

    // state
    bool public canceled;
    uint public highestBindingBid;
    address public highestBidder;
    bool ownerHasWithdrawn;
    mapping(address => uint256) public amountBid;
    mapping(address => uint) public daysRepair;
    mapping(address => string) public dateCompleted;
    mapping(address => string) public methodRepair;
    

    event LogBid(address bidder, uint bid, uint daysRepair, string dateCompleted, string methodRepair);
    // event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();
    
    // StartMin, EndMin, NumContainer, Manufacturer, DateMade, PartRepair, ReqRepair, Region

    function Auction(address _owner, uint _startMin, uint _endMin, string _numContainer, 
                    string _manufacturer, string _dateMade, string _partRepair, string _reqRepair, string _region) {
        // if (_startBlock >= _endBlock) throw;
        // if (_startBlock < block.number) throw;
        if (_owner == 0) throw;

        owner = _owner;
        startBlock = block.number + _startMin*60/15;
        endBlock = block.number + _endMin*60/15;
        numContainer = _numContainer;
        manufacturer = _manufacturer;
        dateMade = _dateMade;
        partRepair = _partRepair;
        reqRepair = _reqRepair;
        region = _region;
    }

    function getHighestBid()
        constant
        returns (uint)
    {
        return fundsByBidder[highestBidder];
    }
    
    // daysRepair, dateCompleted, methodRepair

    function placeBid(uint _daysRepair, string _dateCompleted, string _methodRepair)
        payable
        onlyAfterStart
        onlyBeforeEnd
        onlyNotCanceled
        onlyNotOwner
        returns (bool success)
    {
        // reject payments of 0 ETH
        if (msg.value == 0) throw;
        amountBid[msg.sender] = msg.value;
        daysRepair[msg.sender] = _daysRepair;
        dateCompeted[msg.sender] = _dateCompleted;
        methodRepair[msg.sender] = _methodRepair;
        
        LogBid(msg.sender, amountBid[msg.sender], daysRepair[msg.sender], dateCompeted[msg.sender], methodRepair[msg.sender]);
        return true;
    }

    function min(uint a, uint b)
        private
        constant
        returns (uint)
    {
        if (a < b) return a;
        return b;
    }

    function cancelAuction()
        onlyOwner
        onlyBeforeEnd
        onlyNotCanceled
        returns (bool success)
    {
        canceled = true;
        LogCanceled();
        return true;
    }

    function withdraw()
        onlyEndedOrCanceled
        returns (bool success)
    {
        address withdrawalAccount;
        uint withdrawalAmount;

        if (canceled) {
            // if the auction was canceled, everyone should simply be allowed to withdraw their funds
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];

        } else {
            // the auction finished without being canceled

            if (msg.sender == owner) {
                // the auction's owner should be allowed to withdraw the highestBindingBid
                withdrawalAccount = highestBidder;
                withdrawalAmount = highestBindingBid;
                ownerHasWithdrawn = true;

            } else if (msg.sender == highestBidder) {
                // the highest bidder should only be allowed to withdraw the difference between their
                // highest bid and the highestBindingBid
                withdrawalAccount = highestBidder;
                if (ownerHasWithdrawn) {
                    withdrawalAmount = fundsByBidder[highestBidder];
                } else {
                    withdrawalAmount = fundsByBidder[highestBidder] - highestBindingBid;
                }

            } else {
                // anyone who participated but did not win the auction should be allowed to withdraw
                // the full amount of their funds
                withdrawalAccount = msg.sender;
                withdrawalAmount = fundsByBidder[withdrawalAccount];
            }
        }

        if (withdrawalAmount == 0) throw;

        fundsByBidder[withdrawalAccount] -= withdrawalAmount;

        // send the funds
        if (!msg.sender.send(withdrawalAmount)) throw;

        LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

        return true;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    modifier onlyNotOwner {
        if (msg.sender == owner) throw;
        _;
    }

    modifier onlyAfterStart {
        if (block.number < startBlock) throw;
        _;
    }

    modifier onlyBeforeEnd {
        if (block.number > endBlock) throw;
        _;
    }

    modifier onlyNotCanceled {
        if (canceled) throw;
        _;
    }

    modifier onlyEndedOrCanceled {
        if (block.number < endBlock && !canceled) throw;
        _;
    }
}


