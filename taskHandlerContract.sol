// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract ToDo {

    struct task {
    string work;
    bool status;
    }

    uint revenue;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    mapping(address => task[]) taskList; 
    mapping(address => uint256) rewardList; 

    event taskCreated(uint id, string work, bool status);
    event TaskToggled(uint id, string work, bool status);
    event TaskCompleted(address addr);
    event WithDraw(uint value);

    error TaskNotExist(uint id);
    error TaskNotComplete(uint id);
    error TransactionFailed(uint value);
    error NotAnOwner(address _addr);

    modifier taskExist(uint _id){
        if(taskList[msg.sender].length <= _id) {
            revert TaskNotExist(_id);
        }
        _;
    }

    modifier onlyOwner(){
        if(msg.sender != owner) {
            revert NotAnOwner(msg.sender);
        }
        _;
    }


    function completeTask() external payable  {
        for(uint i = 0; i <= taskList[msg.sender].length; i++) {
            if(!taskList[msg.sender][i].status) {
                revert TaskNotComplete(i);
            }
        }

        uint reward = rewardList[msg.sender];
        uint charges = reward * 1/100;

        (bool sent, bytes memory data) = payable(msg.sender).call{value:reward - charges}("");

        if(!sent) {
            revert TransactionFailed(reward - charges);
        }

        revenue += reward;
        delete taskList[msg.sender];
        rewardList[msg.sender] = 0;
        emit TaskCompleted(msg.sender);
    }


    function createTask(string calldata _work) external payable  {
        require(msg.value == 0.1 ether, "Pay 0.1 eth");
        taskList[msg.sender].push(task(_work, false));
        rewardList[msg.sender] += msg.value;
        emit taskCreated(taskList[msg.sender].length - 1, _work, false);
    } 

    function getTask() external view  returns(task[] memory) {
        return taskList[msg.sender];
    }

    function toggleTask(uint _id) external taskExist(_id) {
        taskList[msg.sender][_id].status = ! taskList[msg.sender][_id].status;
        emit TaskToggled(_id, taskList[msg.sender][_id].work, taskList[msg.sender][_id].status);
    }

    function getReward() external view returns (uint256) {
        return rewardList[msg.sender];
    }

    function getRevenue() external view onlyOwner returns (uint256) {
        return revenue;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function withDraw() external onlyOwner payable {
        (bool sent, bytes memory data) = payable(owner).call{value:revenue}("");
        emit WithDraw(revenue);
        revenue = 0;

    }
}