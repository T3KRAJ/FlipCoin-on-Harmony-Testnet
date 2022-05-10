// SPDX-License-Identifier: UNLICENSED

// Version of soldity and its compiler
pragma solidity ^0.8.7;

// Contract Object
contract FlipCoin{
    // State variables:
    address owner;

    struct User{
        address walletAddress;
        uint betAmount;
        uint betCount;
        uint choice; /* Head: 0 and Tail: 1 */
        uint balance;
        bool betPlaced;
    }
    mapping(address => User) addressToUser;
    User[] public bettors;

    // Events:
	event betCompleted(address bettor, uint winingAmout);
	event betPlaced(address bettor, uint betChoice, uint betAmount);

    constructor(){
        // One who will deploy the contract will be the owner of the contract.
        owner = msg.sender;
    }

    /* User can place a bet on a particular outcome of a coin flip.
    @param _choice: bet = 0 or 1 representing heads or tails.
    @param _betprice: bet amount*/
    function placeBet(uint _choice, uint _betprice) public {
        // By default, each user gets 100 points free to start.
        uint userBetCount = addressToUser[msg.sender].betCount;
        if(userBetCount == 0) addressToUser[msg.sender].balance = 100;

        // Error Handling:
        require(_choice == 1 || _choice == 0, "Invalid Choice!");

        // Same users cannot place multiple bets if they have an existing undecided bet.
        require(addressToUser[msg.sender].betPlaced == false, "Previous bet is not completed yet!");
        
        // User cannot place a bet more than the balance they have.
        require(addressToUser[msg.sender].balance >= _betprice, "Insufficient balance!");
        
        User storage obj = addressToUser[msg.sender];
        obj.walletAddress = msg.sender;
        obj.betAmount = _betprice;
        obj.betCount = userBetCount+1;
        obj.choice =  _choice;
        obj.balance = addressToUser[msg.sender].balance - _betprice;
        obj.betPlaced = true;
        bettors.push(obj);
        // Emit an event when bet is placed successfully. 
        emit betPlaced(msg.sender, _choice, _betprice);
    }

    //Harmony VRF to generate a random number.
    function vrf() public view returns (bytes32 result) {
        uint[1] memory bn;
        bn[0] = block.number;

        // Assembly for more efficient computing:
        assembly {
        let memPtr := mload(0x40)
        // This initiates a low-level staticcall instruction with a given payload or transaction data and
        // returns a Boolean condition along with the return data.
        // Upon failure of the transaction, it returns false.
        if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
            invalid()
        }
        result := mload(memPtr)
        }
    }

    // Generate random num (0 or 1) and conclude all bets with win/loss.
    function rewardBettors() external {
        // A owner only has the permission to announce the bet result and reward the winners.
        require(msg.sender == owner, "Unauthorized User!");
        // 32 bytes value returned from VRF is converted into uint.
        uint rand = uint(vrf());
        for (uint i = 0; i < bettors.length; i++){
            if (bettors[i].choice == rand % 2){
                // Winners will receive double amount of their bet in their balance.
                addressToUser[bettors[i].walletAddress].balance += 2 * bettors[i].betAmount;
                // Emit an event containing gambler address and bet amount for every win.
		        emit betCompleted(bettors[i].walletAddress, bettors[i].betAmount);
            }
            addressToUser[bettors[i].walletAddress].betPlaced = false;
        }
        // Bet Concluded.
        for(uint i=0; i<bettors.length;i++){
            bettors.pop();
        }
    }

    // Getter Function:
	function getUserData(address _id) public view returns(User memory) {
		return addressToUser[_id];
	}
}
