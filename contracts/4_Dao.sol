// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract DAO{

    struct Praposal {
        uint id;
        string descripation;
        uint amount;
        address payable receipient;
        uint vote;
        uint end;
        bool isExcueted;
    }

    mapping (address => bool) private isInvestor;
    mapping (address => uint) public numOfShare;
    mapping (address => mapping (uint => bool)) public isVoted;
    mapping (address => mapping (address => bool)) public withdrawalStatus;
    address [] public InvestorList;
    mapping (uint => Praposal) public praposals;

    uint public totalNoShare;
    uint public avaiableFunds;
    uint public contributionTimeEnd;
    uint public nextPraposalId;
    uint public voteTime;
    uint public quroum;
    address public manager;

    constructor(uint _contributionTimeEnd,uint _voteTime, uint _quroum){
        require(_quroum>=0 && _quroum <=100,"Enter valid Quroum");
        contributionTimeEnd = block.timestamp + _contributionTimeEnd;
        voteTime =  _voteTime;
        quroum = _quroum;
        manager = msg.sender;
    }

    modifier onlyInvestor(){
        require(isInvestor[msg.sender]==true,"You are not investor");
        _;
    }

    modifier onlyManager(){
        require(manager==msg.sender,"You are not manager");
        _;
    }

    function contribution() public payable {
        require(contributionTimeEnd > block.timestamp , "contribution time ended!");
        require(msg.value>0,"Enter valid amount");
        isInvestor[msg.sender] = true;
        numOfShare[msg.sender] += msg.value;
        totalNoShare+=msg.value;
        avaiableFunds+=msg.value;
        InvestorList.push(msg.sender);
    }

    function reedemShare(uint amount) public onlyInvestor(){
        require(numOfShare[msg.sender] >= amount,"dont have enough amount");
        require(avaiableFunds >= amount, "Enter valid fuund");
        numOfShare[msg.sender] -= amount;
        if(numOfShare[msg.sender]==0){
            isInvestor[msg.sender] = false;
        }
        avaiableFunds -= amount;
        payable(msg.sender).transfer(amount);
    }

    function transferShare(uint amount, address to) public onlyInvestor(){
        require(numOfShare[msg.sender] >= amount,"Dont have enough amount");
        require(isInvestor[to]==true,"its not Investor");
        numOfShare[msg.sender] -= amount;
        if(numOfShare[msg.sender]==0){
            isInvestor[msg.sender] = false;
        }
        numOfShare[to]+=amount;
    } 

    function createProposal(string calldata _descripation, uint _amount, address payable _receipient) public onlyManager() {
        require(avaiableFunds >= _amount,"Not enough funds");
        praposals[nextPraposalId] = Praposal(nextPraposalId, _descripation, _amount, _receipient,0,block.timestamp + voteTime,false);
        nextPraposalId++;
    }

    function votePraposal(uint parposalId) public onlyInvestor() {
        Praposal storage proposal = praposals[parposalId];
        require(isVoted[msg.sender][parposalId]==false,"already voted!!");
        require(proposal.end >= block.timestamp,"voting time ended");
        require(proposal.isExcueted==false,"Already excited!");
        isVoted[msg.sender][parposalId] = true;
        proposal.vote += numOfShare[msg.sender];
    }

    function executeParposal(uint parposalId) public onlyManager() {
        Praposal storage proposal = praposals[parposalId];
        require(proposal.vote*100/totalNoShare >= quroum, "not majority");
        proposal.isExcueted = true;
        _transfer(proposal.amount,proposal.receipient);
        avaiableFunds-=proposal.amount;
    }

    function _transfer(uint amount,address payable to) public payable {
        to.transfer(amount);
    }

    function ProposalList() public view returns(Praposal[] memory){
        Praposal[] memory arr = new Praposal[](nextPraposalId -1);
        for(uint i=0;i<nextPraposalId;i++){
            arr[i-1] = praposals[i];
        }
        return arr;
    }
}
