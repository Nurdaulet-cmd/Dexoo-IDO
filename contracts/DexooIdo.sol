// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract IDO is Ownable, Pausable {
    using SafeERC20 for IERC20;
    // <================================ CONSTANTS ================================>
    uint8 constant TEAM_PERCENTAGE = 10;
    uint8 constant TEAM_FREEZE_DURATION_IN_MONTHS = 12;
    uint8 constant TEAM_LOCK_DURATION_IN_MONTH = 24;
    uint8 constant PUBLIC_IMMEDIATE_UNLOCK_PERCENTAGE = 20;
    uint8 constant PUBLIC_UNLOCK_PER_MONTH_PERCENTAGE = 10;
    uint8 constant PUBLIC_LOCK_DURATION_IN_MONTHS =10;
    uint8 constant PRESALE_IMMEDIATE_UNLOCK_PERCENTAGE = 25;
    uint8 constant PRESALE_LOCK_DURATION_IN_MONTHS = 15;
    uint8 constant FOUNDATION_FREEZE_DURATION_IN_MONTHS = 12;
    uint8 constant FOUNDATION_LOCK_DURATION_IN_MONTHS = 10;
    uint8 constant STAKING_PERCENTAGE = 20;
    uint8 constant STAKING_LOCK_DURATION_IN_MONTH = 24;
    uint8 constant ADVISORS_PERCENTAGE = 5;
    uint8 constant ADVISORS_FREEZE_DURATION_MONTHS = 12;
    uint8 constant ADVISORS_LOCK_DURATION_IN_MONTHS = 18;
    uint8 constant LIQUIDITY_PERCENTAGE = 10;
    uint8 constant YIELD_FARMING_PERCENTAGE = 30;
    uint8 constant YIELD_FARMING_VESTING_PERIOD = 12;
    uint8 constant YIELD_FARMING_FIRST_YEAR_LOCK_DURATION_IN_MONTHS = 12;
    uint8 constant YIELD_FARMING_SECOND_YEAR_LOCK_DURATION_IN_MONTHS = 12;


    event TokensTransferedToStakingBalance(address indexed sender, uint256 indexed amount);

    event ShareReleased(address indexed beneficiary, uint256 indexed amount);

    event TokensPurchased(address indexed buyer, uint256 spentAmount, uint256 indexed issuedAmount);

    event TokensUnlocked(address indexed buyer, uint256 unlockedAmount);

    
    // <================================ MODIFIERS ================================>
    modifier contractNotStarted() {
        require(_contractStarted == false, "IDO: The IDO contract has already started");
        _;
    }

    struct Share {
        address shareAddress;
        uint256 share;
        uint256 releaseTime;
        uint256 initialTotalBalance;
        uint256 lastWithdraw;
    }

    // PSBuyer stands for Public Sale Buyer
    struct PSBuyer {
        uint256 lastWithdraw;
        uint256 initialTotalBalance;
        uint256 balance;
        uint256 immediateBalance;
    }

    struct AirDropBuyer {
        uint256 totalSupply;
        uint256 balance;
        address airDropAddress;
        uint16 totalCount;
    }

    struct PreSaleBuyer {
        uint256 lastWithdraw;
        uint256 initialTotalBalance;
        uint256 balance;
        uint256 immediateBalance;
    }


    struct FoundationShare {
        uint256 lastWithdraw;
        uint256 initialTotalBalance;
        uint256 balance;
        address foundationAddress;
    }

    struct StakingShare {
        uint256 lastWithdraw;
        uint256 initialTotalBalance;
        uint256 balance;
        address stakingAddress;
    }

    struct YieldFarmingShare {
        uint256 lastWithdraw;
        uint256 initialTotalBalanceFirstYear;
        uint256 initialTotalBalanceSecondYear;
        uint256 balance;
        address yieldFarmingAddress;
        uint256 releaseFirstYearTime;
        

    }

    struct AdvisorShare {
        uint256 lastWithdraw;
        uint256 releaseTime;
        uint256 initialTotalBalance;
        uint256 balance;
        address advisorAddress;

    }

    struct PublicSale {
        uint256 supply;
        uint256 unlockStartDate;
    }

    struct PreSale {
        uint256 supply;
        uint256 unlockStartDate;
    }
    
    // <================================ CONSTRUCTOR AND INITIALIZER ================================>

    constructor(
        address dexooAddress, 
        address busdAddress,
        address teamAddress,
        address foundationAddress,
        address stakingAddress,
        address liquidityAddress,
        address yieldFarmingAddress,
        address advisorAddress,
        address airDropAddress) 
    {
        require(dexooAddress != address(0), "IDO: DEXOO token address must not be zero");
        require(busdAddress != address(0), "IDO: BUSD token address must not be zero");
        require(teamAddress != address(0), "IDO: Team address must not be zero");
        require(foundationAddress != address(0), "IDO: Team address must not be zero");
        require(stakingAddress != address(0), "IDO: Staking address must not be zero");
        require(liquidityAddress != address(0), "IDO: Liquidity address must not be zero");
        require(yieldFarmingAddress != address(0), "IDO: Liquidity address must not be zero");
        require(advisorAddress != address(0), "IDO: Liquidity address must not be zero");
        require(airDropAddress != address(0), "IDO: Liquidity address must not be zero");


        _dexoo = IERC20(dexooAddress);
        _busd = IERC20(busdAddress);
        
        _teamShare.shareAddress = teamAddress;
        _foundationShare.foundationAddress = foundationAddress;
        _stakingShare.stakingAddress = stakingAddress;
        _liquidityAddress = liquidityAddress;      
        _airDropAddress = airDropAddress;
        _farmingShare.yieldFarmingAddress = yieldFarmingAddress;  
        _farmingShare.releaseFirstYearTime = block.timestamp + _monthsSinceDate(YIELD_FARMING_VESTING_PERIOD);
        _teamShare.releaseTime = block.timestamp + _monthsToTimestamp(TEAM_FREEZE_DURATION_IN_MONTHS);
        _advisorShare.advisorAddress = advisorAddress;
        _pause();
    }
    
    function initialize()
        external
        onlyOwner
        contractNotStarted
    {
        uint256 totalSupply = _dexoo.totalSupply();
        uint256 initialSupply = 900000000 * 10 ** 6;

        _teamShare.share = (totalSupply * TEAM_PERCENTAGE) / 100;
        _teamShare.initialTotalBalance = 3750000 * 10 ** 6;
        _publicSale.supply = 76500000 * 10 ** 6;
        _preSale.supply = 13500000 * 10 ** 6;
        _foundationShare.balance = 121500000 * 10 ** 6; 
        _foundationShare.initialTotalBalance = 12150000 * 10 ** 6;
        _stakingShare.balance = (totalSupply * STAKING_PERCENTAGE) / 100;
        _stakingShare.initialTotalBalance = 7500000 * 10 ** 6;
        liquidityBalance = 90000000 * 10 ** 6;
        airDropBalance = 9000000 * 10 ** 6;
        _farmingShare.balance = (totalSupply * YIELD_FARMING_PERCENTAGE) / 100;
        _farmingShare.initialTotalBalanceFirstYear = 15000000 * 10 **6;
        _farmingShare.initialTotalBalanceSecondYear = 7500000 * 10 ** 6;
        _advisorShare.balance = 45000000 * 10 ** 6;
        _advisorShare.initialTotalBalance = 2500000 * 10 ** 6;
        _contractStarted = true;
        _startDate = (block.timestamp - (block.timestamp % 1 days)) + 10 hours;
        transferTokensToContract(initialSupply);
        _unpause();
    }

    IERC20 public _dexoo;
    IERC20 public _busd;
    uint256 public _startDate;
    Share public _teamShare;
    address public _liquidityAddress;
    uint256 private liquidityBalance;
    address _airDropAddress;
    uint256 private airDropBalance;
    PublicSale public _publicSale;
    PreSale public _preSale;
    FoundationShare public _foundationShare;
    StakingShare public _stakingShare;
    YieldFarmingShare public _farmingShare;
    AdvisorShare public _advisorShare;
    bool public _contractStarted; // true when contract has been initialized
    bool public _publicSaleEnded; // true if ended and false if still active
    mapping (address => PSBuyer) private psBuyers;
    mapping (address => PreSaleBuyer) private preSaleBuyers;
    mapping(address => AirDropBuyer) private airDropBuyers;
    // <================================ EXTERNAL FUNCTIONS ================================>
 
    function withdrawPreSaleUnlockedTokens()
    external
    whenNotPaused
    returns(bool) {
        address buyer = _msgSender();
        uint256 monthsSinceDate = _monthsSinceDate(_publicSale.unlockStartDate);
        require(isPresaleBuyer(buyer), "IDO: The user hasn't participated in Pre Sale or has already withdrawn all his balance");
        require(!_publicSaleEnded, "IDO: Public sale has already finished");
        PreSaleBuyer storage preSaleBuyer = preSaleBuyers[buyer];
        require(buyer != address(0), "IDO: Token issue to Zero address is prohibited");
        uint256 dexooToUnlock;
        if (preSaleBuyer.immediateBalance != 0) {
            dexooToUnlock = preSaleBuyer.immediateBalance;
            _dexoo.safeTransfer(buyer, dexooToUnlock);
            return true;

        }
        else{
            require(preSaleBuyer.lastWithdraw < PRESALE_LOCK_DURATION_IN_MONTHS, "IDO: Buyer has already withdrawn all available unlocked tokens");
            require(monthsSinceDate != preSaleBuyer.lastWithdraw, "IDO: Buyer has already withdrawn tokens this month");
            if(monthsSinceDate >= PRESALE_LOCK_DURATION_IN_MONTHS){
                 dexooToUnlock = preSaleBuyer.balance;
                _removePreSaleBuyer(buyer);
            }else {
                dexooToUnlock = preSaleBuyer.balance / PRESALE_LOCK_DURATION_IN_MONTHS;
                preSaleBuyer.balance -= dexooToUnlock;
                preSaleBuyer.lastWithdraw = monthsSinceDate;

            }
            _dexoo.safeTransfer(buyer, dexooToUnlock);
        
            emit TokensUnlocked(buyer, dexooToUnlock);
            return true;

        }
    }

    function withdrawnAirDropTokens() external whenNotPaused returns(bool) {
        address buyer = _msgSender();
        uint256 monthsSinceDate = _monthsSinceDate(_publicSale.unlockStartDate);
        require(isAirDropBuyer(buyer), "IDO: The user hasn't participated in Pre Sale or has already withdrawn all his balance");
        require(!_publicSaleEnded, "IDO: Public sale has already finished");
        AirDropBuyer storage airDropBuyer = airDropBuyers[buyer];
        require(buyer != address(0), "IDO: Token issue to Zero address is prohibited");
        uint256 dexooToUnlock = airDropBuyer.balance / airDropBuyer.totalCount;
        
        _dexoo.safeTransfer(buyer, dexooToUnlock);
        return true;

        }

    function withdrawAirdrodOwnerTokens() external whenNotPaused  returns(bool) {
        address tokenOwner = _msgSender();
        require(tokenOwner == _airDropAddress, "IDO: Withdrawal is available only to the airdrop owner");
        
        _dexoo.safeTransfer(tokenOwner, airDropBalance);
        
        emit TokensUnlocked(tokenOwner, airDropBalance);
        return true;
    }



    function withdrawPublicUnlockedTokens()
    external
    whenNotPaused
    returns(bool) {
        address buyer = _msgSender();
        uint256 monthsSinceDate = _monthsSinceDate(_publicSale.unlockStartDate);
        require(isPublicSaleBuyer(buyer), "IDO: The user hasn't participated in Pre Sale or has already withdrawn all his balance");
        require(!_publicSaleEnded, "IDO: Public sale has already finished");
        PSBuyer storage psBuyer = psBuyers[buyer];
        require(buyer != address(0), "IDO: Token issue to Zero address is prohibited");
        uint256 dexooToUnlock;
        if (psBuyer.immediateBalance != 0) {
            dexooToUnlock = psBuyer.immediateBalance;
            _dexoo.safeTransfer(buyer, dexooToUnlock);
            return true;

        }
        else{
            require(psBuyer.lastWithdraw < PUBLIC_LOCK_DURATION_IN_MONTHS, "IDO: Buyer has already withdrawn all available unlocked tokens");
            require(monthsSinceDate != psBuyer.lastWithdraw, "IDO: Buyer has already withdrawn tokens this month");
            if(monthsSinceDate >= PRESALE_LOCK_DURATION_IN_MONTHS){
                 dexooToUnlock = psBuyer.balance;
                _removePublicSaleBuyer(buyer);
            }else {
                dexooToUnlock = psBuyer.balance / PUBLIC_LOCK_DURATION_IN_MONTHS;
                psBuyer.balance -= dexooToUnlock;
                psBuyer.lastWithdraw = monthsSinceDate;

            }
            _dexoo.safeTransfer(buyer, dexooToUnlock);
        
            emit TokensUnlocked(buyer, dexooToUnlock);
            return true;

        }
    }

    function withdrawAdvisorUnlockedTokens() external whenNotPaused returns(bool){
        
       require(block.timestamp >= _advisorShare.releaseTime, "IDO: Time is not up. Cannot release share");
        address tokenOwner = _msgSender();
        uint256 monthsSinceDate = _monthsSinceDate(_publicSale.unlockStartDate);
        require(tokenOwner == _advisorShare.advisorAddress, "IDO: Withdrawal is available only to the advisor");
        require(_advisorShare.lastWithdraw < ADVISORS_LOCK_DURATION_IN_MONTHS, "IDO: Buyer has already withdrawn all available unlocked tokens");
        require(monthsSinceDate != _advisorShare.lastWithdraw, "IDO: Buyer has already withdrawn tokens this month");
        uint256 dexooToUnlock;
        
        dexooToUnlock = _advisorShare.initialTotalBalance;
        _advisorShare.balance -= dexooToUnlock;
        _advisorShare.lastWithdraw = monthsSinceDate;
    
        _dexoo.safeTransfer(tokenOwner, dexooToUnlock);
        
        emit TokensUnlocked(tokenOwner, dexooToUnlock);
        return true;
    }


      function withdrawLiquidityUnlockedTokens() external whenNotPaused returns(bool) {
        address tokenOwner = _msgSender();
        require(tokenOwner == _liquidityAddress, "IDO: Withdrawal is available only to the liquidity");
        
        _dexoo.safeTransfer(tokenOwner, liquidityBalance);
        
        emit TokensUnlocked(tokenOwner, liquidityBalance);
        return true;
    }


    function withdrawFarmingUnlockedTokens() external whenNotPaused {
        address tokenOwner = _msgSender();
        require(tokenOwner == _farmingShare.yieldFarmingAddress, "IDO: Withdrawal is available only to the farming");
        uint256 monthsSinceDate = _monthsSinceDate(_publicSale.unlockStartDate);
        uint256 dexooToUnlock;
        if(block.timestamp >= _farmingShare.releaseFirstYearTime){
            require(_farmingShare.lastWithdraw < YIELD_FARMING_FIRST_YEAR_LOCK_DURATION_IN_MONTHS, "IDO: Buyer has already withdrawn all available unlocked tokens");
            dexooToUnlock = _farmingShare.initialTotalBalanceFirstYear;
            _farmingShare.balance -= dexooToUnlock;
            _farmingShare.lastWithdraw = monthsSinceDate;
    
            _dexoo.safeTransfer(tokenOwner, dexooToUnlock);
        }else if (block.timestamp < _farmingShare.releaseFirstYearTime) {
            require(_farmingShare.lastWithdraw < YIELD_FARMING_SECOND_YEAR_LOCK_DURATION_IN_MONTHS, "IDO: Buyer has already withdrawn all available unlocked tokens");
            dexooToUnlock = _farmingShare.initialTotalBalanceSecondYear;
            _farmingShare.balance -= dexooToUnlock;
            _farmingShare.lastWithdraw = monthsSinceDate;
    
            _dexoo.safeTransfer(tokenOwner, dexooToUnlock);

        }

    }    



    function withdrawTeamShare() external  whenNotPaused {
        require(_withdrawShare(_teamShare));
    }

    // <================================ ADMIN FUNCTIONS ================================>

    function pauseContract() external onlyOwner whenNotPaused
    {
        _pause();
    }

    function endPublicSale() external onlyOwner whenNotPaused 
    {
        _endPublicSale();
    }

    function unPauseContract() external onlyOwner whenPaused
    {
        _unpause();
    }

    function isPublicSaleBuyer(address buyer) public view returns(bool) {
        if(psBuyers[buyer].initialTotalBalance != 0) {
            return true;
        }
        return false;
    }

    function isPresaleBuyer(address buyer) public view returns(bool) {
         if(preSaleBuyers[buyer].initialTotalBalance != 0) {
            return true;
        }
        return false;
    }

     function isAirDropBuyer(address buyer) public view returns(bool) {
         if(airDropBuyers[buyer].balance != 0) {
            return true;
        }
        return false;
    }



    function transferTokensToContract(uint256 amount) public onlyOwner
    {
        address owner = _msgSender();
        _dexoo.safeTransferFrom(owner, address(this), amount);
        emit TokensTransferedToStakingBalance(owner, amount);
    }

    function withdrawBUSD() external onlyOwner returns (bool) {
        address owner = _msgSender();
        uint256 balanceBUSD = _busd.balanceOf(address(this));
        require(balanceBUSD > 0, "IDO: Nothing to withdraw. Ido contract's BUSD balance is empty");
        _busd.safeTransfer(owner, balanceBUSD);
        return true;
    }

    function withdrawLeftPublicTokens() external onlyOwner returns (bool) {
        address owner = _msgSender();
        require(_publicSaleEnded, "IDO: Can not withdraw. Public sale is still active");
        require(_publicSale.supply > 0, "IDO: Nothing to withdraw. Ido contract's BUSD balance is empty");
        _dexoo.safeTransfer(owner, _publicSale.supply);
        _publicSale.supply = 0;
        return true;
    }

    function finalize() external onlyOwner {
        address owner = _msgSender();
        require(_publicSaleEnded, "IDO: Can not withdraw balance yet. Public Sale is not over yet");
        uint256 balanceBUSD = _busd.balanceOf(address(this));
        uint256 balanceDexoo = _dexoo.balanceOf(address(this));
        if(balanceBUSD > 0) _busd.safeTransfer(owner, balanceBUSD);
        if(balanceDexoo > 0)  _dexoo.safeTransfer(owner, balanceDexoo);
        _pause();
        selfdestruct(payable(owner));
    }

    // <================================ INTERNAL & PRIVATE FUNCTIONS ================================>
    function _withdrawShare(Share memory share) internal returns(bool) {
        require(block.timestamp >= _teamShare.releaseTime, "IDO: Time is not up. Cannot release share");
        address tokenOwner = _msgSender();
        uint256 monthsSinceDate = _monthsSinceDate(_publicSale.unlockStartDate);
        require(tokenOwner == _teamShare.shareAddress, "IDO: Withdrawal is available only to the advisor");
        require(share.lastWithdraw < TEAM_LOCK_DURATION_IN_MONTH, "IDO: Buyer has already withdrawn all available unlocked tokens");
        require(monthsSinceDate != _teamShare.lastWithdraw, "IDO: Buyer has already withdrawn tokens this month");
        uint256 dexooToUnlock;
        
        dexooToUnlock = _teamShare.initialTotalBalance;
        _teamShare.share -= dexooToUnlock;
        _teamShare.lastWithdraw = monthsSinceDate;
    
        _dexoo.safeTransfer(tokenOwner, dexooToUnlock);
        
        emit TokensUnlocked(tokenOwner, dexooToUnlock);
        return true;
    }

    function _monthsSinceDate(uint256 _timestamp) private view returns(uint256){
        return  (block.timestamp - _timestamp) / 30 days;
    }

    function _daysSinceDate(uint256 _timestamp) private view returns(uint256){
        return  (block.timestamp - _timestamp) / 1 days;
    }

    function getBuyerLockedBalance(address buyer) external view returns(uint256){
        return psBuyers[buyer].balance;
    }

    function getBuyerLastWithdraw(address buyer) external view returns(uint256){
        return psBuyers[buyer].lastWithdraw;
    }

    function getPublicSaleLeftSupply() external view returns(uint256){
        return _publicSale.supply;
    }

    function getCurrentMonth() external view returns(uint256) {
        return _publicSale.unlockStartDate == 0 ? 0 : _monthsSinceDate(_publicSale.unlockStartDate);
    }

    function isPublicSaleActive() external view returns(bool) {
        return !_publicSaleEnded;
    }

    function isTokensUnlockActive() external view returns(bool) {
        uint256 monthsSinceDate = _monthsSinceDate(_publicSale.unlockStartDate);
        return monthsSinceDate > 0 && _publicSaleEnded;
    }

    function getTokenPrice() public pure returns(uint256) {
        uint256 price = 90000000000000000; // 0,09$

        return price;
    }
    
    function _issueTokens(address buyer, uint256 busdToPay, uint256 dexooToIssue) private returns(bool) {
        uint256 dexooToUnlock = (dexooToIssue * PUBLIC_IMMEDIATE_UNLOCK_PERCENTAGE) / 100;
        
        _busd.safeTransferFrom(buyer, address(this), busdToPay);
        _dexoo.safeTransfer(buyer, dexooToUnlock);
        _publicSale.supply -= dexooToIssue;
        if(_publicSale.supply == 0) {
            _endPublicSale();
        }

        PSBuyer storage psBuyer = psBuyers[buyer];
        psBuyer.initialTotalBalance += dexooToIssue;
        psBuyer.balance += dexooToIssue - dexooToUnlock;

        emit TokensPurchased(buyer, busdToPay, dexooToIssue);
        return true;
    }

    function _endPublicSale() private {
        require(!_publicSaleEnded, "IDO: Public sale has already finished");
        _publicSale.unlockStartDate = _startDate + (_daysSinceDate(_startDate) * 1 days) + 1 days;
        _publicSaleEnded = true;
    }

    function _removePublicSaleBuyer(address buyer) private {
        if(isPublicSaleBuyer(buyer)) {
            delete psBuyers[buyer];
        }
    }

    function _removePreSaleBuyer(address buyer) private {
        if(isPresaleBuyer(buyer)) {
            delete preSaleBuyers[buyer];
        }
    }

    function _monthsToTimestamp(uint256 months) internal pure returns(uint256) {
        return months * 30 days;
    }

    function toMegaToken(uint256 amount) internal pure returns(uint256) {
        return amount * (10 ** decimals());
    }

    function decimals() internal pure returns(uint8) {
        return 6;
    }

}