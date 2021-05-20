// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Token{

    struct locking {
        uint value;
        uint time_locked;
    }
    mapping(string => mapping(address => bool)) internal registeredToAirdrop;
    mapping(address => uint) internal balances;
    mapping(address => mapping(address => uint)) internal allowance;
    mapping(address => uint) internal airdropBalance;
    mapping(address => locking) internal lockedAmount;


    uint public totalSupply = 150000000 * 10 ** 18;
    string public name = "freedom.finance";
    string public symbol = "idkyet";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);


    constructor(){
        balances[msg.sender] = totalSupply;
    }

    
    function transfer(address to, uint value) external  payable returns(bool){
        if (block.timestamp >= lockedAmount[msg.sender].time_locked){
            lockedAmount[msg.sender].time_locked = 0;
        }
        require(balances[msg.sender]- lockedAmount[msg.sender].value>= value, "Sorry you dont have enough tokens");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender,to,value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) external  returns(bool){
        require(balances[from] >= value, "Sorry you dont have enough tokens");
        require(allowance[from][msg.sender] >= value, "Allowance too low");
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    } 
    
    function approve(address spender, uint value) external returns(bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function balanceOf(address owner) public view returns(uint){
        return balances[owner];
    }

}


contract Airdrops is Token {

    address airDropAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; // to test;
    address[] internal listOfWinners;
    uint public time;
    uint public withdrawTime;

    struct airDropInfo {
        uint numOfWinners;
        uint moneyToGive;
        uint lockUpPeriod;
        uint amountOfPeople;
        address[] peopleIn;
    }

    mapping(string => airDropInfo) public airDropInformations;

    modifier notRegisteredAlready(string memory airDropName){
        require(registeredToAirdrop[airDropName][msg.sender] == false);
        _;
    }

    modifier hasMoneyToLock(){
        require(balances[msg.sender] > 0);
        _;
    }

    modifier hasMoneyToAirdrop(uint valueToGive){
        require(balances[airDropAddress] > valueToGive, "Airdrop Main Address doesn't have enough money");
        _;
    }

    modifier didRegistrationTimePass(){
        require(block.timestamp < block.timestamp + time * 1 hours);
        _;
    }

    function registerToAirDrop(string memory airDropName) public didRegistrationTimePass returns(bool){
        registeredToAirdrop[airDropName][msg.sender] = true;
        airDropInformations[airDropName].amountOfPeople += 1;
        airDropInformations[airDropName].peopleIn.push(msg.sender);
        return true;
    }

    function random(string memory airDropName) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, airDropInformations[airDropName].peopleIn)));
    }

    function pickWinner(string memory airDropName) private view returns(address){
        uint length1 = airDropInformations[airDropName].amountOfPeople;
        uint index=random(airDropName)%length1;
        address winner = airDropInformations[airDropName].peopleIn[index];
        return winner;
    }

    function withdrawAirdrop(uint amount) public payable returns(bool){
        require(amount <= airdropBalance[msg.sender], "you dont have enough money");
        require(block.timestamp <= withdrawTime);
        balances[msg.sender] += amount;
        airdropBalance[msg.sender] -= amount;
        emit Transfer(address(0), msg.sender, amount);
        return true;
    }

    function startAirdrop(uint numOfTokens, uint numOfWinners, uint timeToJoin, uint lockUpPeriod, string memory airDropName) public hasMoneyToAirdrop(numOfTokens) payable returns(bool){
        balances[airDropAddress] -= numOfTokens;
        time = 0;
        time = timeToJoin;
        uint moneyToGive = numOfTokens/numOfWinners;
        withdrawTime = block.timestamp + lockUpPeriod * 1 hours;
        airDropInformations[airDropName].numOfWinners = numOfWinners;
        airDropInformations[airDropName].moneyToGive = moneyToGive;
        airDropInformations[airDropName].lockUpPeriod = lockUpPeriod;
        return true;
    }   
    
    function drawWinners(string memory airDropName) public returns(bool){
        uint end = airDropInformations[airDropName].numOfWinners;
        for (uint i = 0; i<end; i++){
            listOfWinners.push(pickWinner(airDropName));
            airdropBalance[listOfWinners[i]] = airDropInformations[airDropName].moneyToGive;
        }
        return true;
    }
}

contract Presale is Token{
    
    event Bought(uint256 amount);
    uint price = 10; // in wei (its normally for ETH wei so it will be bnb's "wei" (dunno how is that shit called))
    address public idoAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; // to test;
    uint public totalPresale = 100000000;
    uint public percents = 0;

    function lock(uint time_to_lock, uint amount_to_lock) public returns(bool){
        lockedAmount[msg.sender].value += amount_to_lock;
        lockedAmount[msg.sender].time_locked = block.timestamp + time_to_lock * 1 hours;
        return true;
    }

    function buy() payable public {
        uint256 amountToBuy = msg.value * price;
        require(amountToBuy <= balances[idoAddress], "Not enough tokens in the reserve");
        balances[idoAddress] -= amountToBuy;
        balances[msg.sender] += amountToBuy;
        if (percents <= 33){
            lock(12, amountToBuy);
        }
        else if (percents > 33 && percents <= 66){
            lock(24, amountToBuy);
        }
        else{
            lock(36, amountToBuy);
        }
        percents += uint256((amountToBuy * 100) / totalPresale);
        emit Bought(amountToBuy);
    }

}

contract Staking is Token{

    event StakingRegistration(address indexed from, address indexed to, uint value);
    event StakingWithdraw(address indexed to, uint value);

    struct stakingInfo{
        address[] participants;
        uint timeStaking;
        uint numberOfParticipants;
        uint fullDestributionAmount;
        mapping(address => uint) stakedValueOfAddress;
        mapping(address => bool) isAlreadyRegistered;
        mapping(address => uint) percentageOfPool;
    }

    mapping(string => stakingInfo) public stakingInformations;
    address addressOfStaking = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; // to test;

    function startLockedStaking(uint time, uint amountToDistribute, string memory stakingID) public returns(bool){
        require(balances[addressOfStaking] >= amountToDistribute, "Not enough money on Staking address");
        stakingInformations[stakingID].timeStaking = block.timestamp + time * 1 hours;
        stakingInformations[stakingID].fullDestributionAmount = amountToDistribute;
        balances[addressOfStaking] -= amountToDistribute;
        return true;
    }

    function distributeTokens(string memory stakingName) public returns(bool){
        uint n = stakingInformations[stakingName].numberOfParticipants;
        uint amountToGiveEveryFourHoursForOnePerson = uint(((stakingInformations[stakingName].fullDestributionAmount)/(stakingInformations[stakingName].timeStaking / 4)));
        for (uint i = 0; i<n; i++){
            address person = stakingInformations[stakingName].participants[i];
            uint percentageAmountToGet = uint((stakingInformations[stakingName].percentageOfPool[person] * 100) / amountToGiveEveryFourHoursForOnePerson);
            stakingInformations[stakingName].stakedValueOfAddress[person] += (percentageAmountToGet/100) * amountToGiveEveryFourHoursForOnePerson;
        }
        return true;
    }

    function registerToStaking(string memory stakingName, uint amountToStake) public returns(bool){
        require(stakingInformations[stakingName].isAlreadyRegistered[msg.sender] == false, "you already participate in that Staking");
        require(balances[msg.sender] >= amountToStake);
        stakingInformations[stakingName].participants.push(msg.sender);
        stakingInformations[stakingName].numberOfParticipants++;
        balances[msg.sender] -= amountToStake;
        balances[addressOfStaking] += amountToStake;
        stakingInformations[stakingName].stakedValueOfAddress[msg.sender] += amountToStake;
        stakingInformations[stakingName].percentageOfPool[msg.sender] = amountToStake;
        emit StakingRegistration(msg.sender, addressOfStaking, amountToStake);
        return true;
    }
    
    function recieveStakedTokens(string memory stakingName, uint amountToRecieve) public returns(bool){
        require(block.timestamp >= stakingInformations[stakingName].timeStaking, "You cant get your tokens yet");
        uint howMuchStaked = stakingInformations[stakingName].stakedValueOfAddress[msg.sender];
        require(amountToRecieve <= howMuchStaked);
        balances[msg.sender] += amountToRecieve;
        stakingInformations[stakingName].stakedValueOfAddress[msg.sender] -= amountToRecieve;
        emit StakingWithdraw(msg.sender, amountToRecieve);
        return true;
    }
}

contract Referrals is Token{

    event ReferralsWithdraw(address to, uint amount);
    
    struct RefsInfo{
        address[] peopleRefered;
        uint amountOfPeopleRefered;
        uint bountyTaken;
    }

    mapping(address => RefsInfo) ReferalsInformation;

    function checkRef (address ad) private view returns(bool){
        for (uint i = 0; i<ReferalsInformation[msg.sender].amountOfPeopleRefered; i++){
            if (ReferalsInformation[msg.sender].peopleRefered[i] == ad){
                return false;
            }
        }
        return true;
    }

    function addRef(address referedAddress) public returns(bool){
        require(checkRef(referedAddress) == true, "sorry you already did invite that person");
        ReferalsInformation[msg.sender].peopleRefered.push(referedAddress);
        ReferalsInformation[msg.sender].amountOfPeopleRefered += 1;
        ReferalsInformation[msg.sender].bountyTaken += 100;
        return true;
    }

    function withdrawReferral(uint amount) public returns(bool){
        require(ReferalsInformation[msg.sender].bountyTaken >= amount);
        ReferalsInformation[msg.sender].bountyTaken -= amount;
        balances[msg.sender] += amount;
        emit ReferralsWithdraw(msg.sender, amount);
        return true;
    }

}

contract Gambling is Token {

    event Deposited (uint amount);
    event Withdrawed (address indexed to, uint amount);

    struct participants{
        mapping(address => uint) amountPaid;
        address[] redParticipants;
        address[] blackParticipants;
        address[] greenParticipants;
        uint numberOfRed;
        uint numberOfBlack;
        uint numberOfGreen;
    }
    mapping(address => uint) moneyInTokens;
    mapping(string => participants) IDOfGame;

    function payWinners(string memory gameID, uint colorWon) public{
        uint B = 1;
        uint R = 2;
        uint G = 3;
        if (colorWon == B){
            uint n = IDOfGame[gameID].numberOfBlack;
            for (uint i = 0; i<n; i++){
                address payTo = IDOfGame[gameID].blackParticipants[i];
                moneyInTokens[payTo] += IDOfGame[gameID].amountPaid[payTo] * 2;
            }
        }
        else if (colorWon == R){
            uint n = IDOfGame[gameID].numberOfRed;
            for (uint i = 0; i<n; i++){
                address payTo = IDOfGame[gameID].redParticipants[i];
                moneyInTokens[payTo] += IDOfGame[gameID].amountPaid[payTo] * 2;
            }

        }
        else if (colorWon == G){
            uint n = IDOfGame[gameID].numberOfGreen;
            for (uint i = 0; i<n; i++){
                address payTo = IDOfGame[gameID].greenParticipants[i];
                moneyInTokens[payTo] += IDOfGame[gameID].amountPaid[payTo] * 14;
            }
        }
    }

    function registerToRoulette(string memory gameID, uint colorBet, uint amountToBet) public returns(bool){
        uint B = 1;
        uint R = 2;
        uint G = 3;
        if (colorBet == B){
            IDOfGame[gameID].blackParticipants.push(msg.sender);
            IDOfGame[gameID].numberOfBlack++;
            require(moneyInTokens[msg.sender] >= amountToBet);
            moneyInTokens[msg.sender] -= amountToBet;
            IDOfGame[gameID].amountPaid[msg.sender] += amountToBet;
        }
        else if (colorBet == R){
            IDOfGame[gameID].redParticipants.push(msg.sender);
            IDOfGame[gameID].numberOfRed++;
            require(moneyInTokens[msg.sender] >= amountToBet);
            moneyInTokens[msg.sender] -= amountToBet;
            IDOfGame[gameID].amountPaid[msg.sender] += amountToBet;
        }
        else if (colorBet == G){
            IDOfGame[gameID].greenParticipants.push(msg.sender);
            IDOfGame[gameID].numberOfGreen++;
            require(moneyInTokens[msg.sender] >= amountToBet);
            moneyInTokens[msg.sender] -= amountToBet;
            IDOfGame[gameID].amountPaid[msg.sender] += amountToBet;
        }

        return true;

    }

    function depositTokens(uint amount) public payable returns(bool){
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        moneyInTokens[msg.sender] += amount;
        emit Deposited(amount);
        return true;
    }

    function withdrawTokens (uint amount) public payable returns(bool){
        require(amount <= moneyInTokens[msg.sender]);
        moneyInTokens[msg.sender] -= amount;
        balances[msg.sender] += amount;
        emit Withdrawed(msg.sender, amount);
        return true;
    }
    

    // For Now everyone can run theese functions it will be changed when we specify all owners addresses
}

contract NFT is Token{


}
