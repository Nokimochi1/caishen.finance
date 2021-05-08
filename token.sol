// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Token{

    mapping(string => mapping(address => bool)) internal registeredToAirdrop;
    mapping(address => bool) internal lockedAddresses;
    mapping(address => uint) internal balances;
    mapping(address => mapping(address => uint)) internal allowance;
    mapping(address => uint) internal airdropBalance;


    uint internal totalSupply = 150000000 * 10 ** 18;
    string internal name = "freedom.finance";
    string internal symbol = "idkyet";
    uint internal decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);


    constructor(){
        balances[msg.sender] = totalSupply;
    }

    
    function transfer(address to, uint value) external  payable returns(bool){
        require(balances[msg.sender]>= value, "Sorry you dont have enough tokens");
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
        uint lenght1 = airDropInformations[airDropName].amountOfPeople;
        uint index=random(airDropName)%lenght1;
        address winner = airDropInformations[airDropName].peopleIn[index];
        return winner;
    }

    function withdrawAirdrop(uint amount) public payable returns(bool){
        require(amount <= airdropBalance[msg.sender], "you dont have enough money");
        require(block.timestamp <= withdrawTime);
        balances[msg.sender] += amount;
        airdropBalance[msg.sender] -= amount;
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

contract IDO is Token{

    



}