pragma solidity >=0.7.0 <0.9.0;

/**
 * @title CrowdFunding
 * @dev Implement a simple crowdfunding contract
 */
contract CrowdFunding {
    struct crowdFunding {
        uint id;
        uint needMoney;     
        uint receivedMoney;                             //the money of this crowdfunding has collected.
        uint maxPeople;                                 //max provider number
        address receiver;       
        address[] provider;                             //all provider address
        bool state;                                     //indicate the state of crowdfunding, open or closed.
        mapping(address => uint) providerToMoney;       //a map of provider address => provide money
    }
    
    crowdFunding[] allcrowdFunding;
    
    /*  create some event 
    *   create_CrowdFunding:    emit this event when some user create a new crowdFunding
    *   provide_Money:          emit this event when some provide some money to a crowdFunding
    *   terminal_CrowdFunding:  emit this event when some user cancel their own crowdFunding
    *   get_CrowdFunding:       emit this event when a crowdFunding is finished successful
    *   refuse_CrowdFunding:    emit thsi event when a crowdFunding is canceled or can not finish
    */
    event create_CrowdFunding(address indexed user, uint indexed needMoney, uint indexed maxPeople);
    event provide_Money(uint indexed crowdFundingid, uint indexed value, uint people_count);
    event terminal_CrowdFunding(uint indexed id);
    event get_CrowdFunding(uint indexed id);
    event refuse_CrowdFunding(uint indexed id);
    
    // function of creating a new crowdFunding
    function createCrowdFunding(uint needMoney, uint maxPeople) external{
        //the needMoney and maxPeople should larger than 0.
        require(needMoney > 0, "needMoney should > 0");
        require(maxPeople > 0, "maxPeople should > 0");
        
        crowdFunding storage newcrowdFunding = allcrowdFunding.push();
        newcrowdFunding.id = allcrowdFunding.length - 1;
        newcrowdFunding.needMoney = needMoney * 1 ether;
        newcrowdFunding.receivedMoney = 0;
        newcrowdFunding.maxPeople = maxPeople;
        newcrowdFunding.receiver = msg.sender;
        newcrowdFunding.state = true;
        emit create_CrowdFunding(msg.sender, needMoney, maxPeople);
    }
    
    //function of providing some money to a crowdFunding
    function provideMoney(uint id) external payable {
        
        //this crowdFunding should exist and open.
        require(allcrowdFunding.length > id, "this crowdFunding is not exist");
        crowdFunding storage tempcrowdFunding = allcrowdFunding[id];
        require(tempcrowdFunding.state, "this crowdfunding is closed");
        
        //add the provider address to provider array(if it's the first time to provide money to this crowdfunding)
        if(tempcrowdFunding.providerToMoney[msg.sender] == 0) {
            tempcrowdFunding.provider.push(msg.sender);
        }
        
        tempcrowdFunding.providerToMoney[msg.sender] = tempcrowdFunding.providerToMoney[msg.sender] + msg.value;
        tempcrowdFunding.receivedMoney += msg.value;
        
        //check whether the crowdfunding is finished or not.
        if(checkSuccess(tempcrowdFunding)) {
            //success
            getCrowdFunding(tempcrowdFunding, msg.sender);
            emit get_CrowdFunding(id);
        }else if(checkFailure(tempcrowdFunding)) {
            //fail 
            refuseCrowdFunding(tempcrowdFunding);
            emit refuse_CrowdFunding(id);
        }
        emit provide_Money(id, msg.value, tempcrowdFunding.provider.length);
        
    }
    
    //user terminal their own crowdfunding
    function terminalCrowdFunding(uint id) public {
        require(allcrowdFunding.length > id, "this crowdfunding is not exist");
        require(msg.sender == allcrowdFunding[id].receiver, "this crowdfunding is not belongs to you");
        
        crowdFunding storage tempcrowdFunding = allcrowdFunding[id];
        require(tempcrowdFunding.state, "this crowfunding has closed");
        refuseCrowdFunding(tempcrowdFunding);
        
        emit terminal_CrowdFunding(id);
    }
    
    //check whether the crowdFunding is failed. 
    function checkFailure(crowdFunding storage tempcrowdFunding) view internal returns(bool) {
        return tempcrowdFunding.provider.length > tempcrowdFunding.maxPeople;
    }
    
    //check whether the crowdFunding is finished.
    function checkSuccess(crowdFunding storage tempcrowdFunding) view internal returns(bool) {
        return (tempcrowdFunding.receivedMoney >= tempcrowdFunding.needMoney) && 
        (tempcrowdFunding.provider.length <= tempcrowdFunding.maxPeople);
    }
    
    //when the crowdFunding is finished, receiver get all of the money
    function getCrowdFunding(crowdFunding storage tempcrowdFunding, address lastProvider) internal {
        payable(tempcrowdFunding.receiver).transfer(tempcrowdFunding.needMoney);
        payable(lastProvider).transfer(tempcrowdFunding.receivedMoney - tempcrowdFunding.needMoney);
        //tempcrowdFunding.receivedMoney = 0;
        tempcrowdFunding.state = false;
    }
    
    //when the crowdFunding is failed, return all money
    function refuseCrowdFunding(crowdFunding storage tempcrowdFunding) internal {
        for(uint i = 0; i < tempcrowdFunding.provider.length; i++) {
            payable(tempcrowdFunding.provider[i]).transfer(tempcrowdFunding.providerToMoney[tempcrowdFunding.provider[i]]);
        }
        tempcrowdFunding.state = false;
    }
}