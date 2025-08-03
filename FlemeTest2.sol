// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Importing industry-standard contracts for ERC20 functionality, ownership control, and security:
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FLMTest2 is ERC20, ERC20Burnable, Ownable {
    

/*
HERE CORE COMPONENTS ARE DECLARED: 
*/
    
	// Defines wallets used. 
	// Distribution amounts are defined further down the contract: 
		address public immutable launchWallet;       // Used to populate the DEX liquidity pool; also receives contract ownership
		address public immutable marketingWallet;    // Marketing Funds (90% will be locked in escrow via Flare Finance.) 
		address public immutable devWallet;          // One-time personal allocation for project creator    

	// Creates a timestamp variable for when trading is manually enabled:
		uint256 public tradeEnabledTimestamp;

	// Allows trading to be enabled as a one-time event:
		bool public tradingEnabled = false;
		event TradingEnabled();

	// Defines the total token supply:
		uint256 public constant MAX_SUPPLY = 100_000_000 * 10**18;

/*
HERE THE COMPONENTS ARE ASSEMBLED:
*/

	// Using constructor(), wallets addresses are requested when the contract is deployed:
		constructor(
			address _launchWallet,
			address _marketingWallet,
			address _devWallet
	// Token is named and symbol assigned; contract ownership is transferred to launchWallet 
		) ERC20("FLM Test2", "FLMT2") Ownable(_launchWallet) {
        
	// Ensures all wallet addresses are populated:
        require(_launchWallet != address(0), "Launch wallet cannot be zero address");
        require(_devWallet != address(0), "Dev wallet cannot be zero address");
        require(_marketingWallet != address(0), "Marketing wallet cannot be zero address");

    // Assign wallets:
        launchWallet = _launchWallet;
        devWallet = _devWallet;
        marketingWallet = _marketingWallet;

	// Mints initial token supply to designated wallets:
        _mint(launchWallet, 87_000_000 * 10**18);      // For the initial DEX liquidity pool. 
        _mint(devWallet, 3_000_000 * 10**18);          // 3% for the dev wallet.
        _mint(marketingWallet, 10_000_000 * 10**18);   // 1M will be liquid, 9M will be locked in escrow via Flare Finance.
    }

    // This function enables trading as a one-time event.
    // Once enabled, it cannot be changed (there is no disable function).
		function enableTrading() external onlyOwner {
			require(!tradingEnabled, "Trading already enabled");
			tradingEnabled = true;
			tradeEnabledTimestamp = block.timestamp;

	// Record when trading is enabled:
			emit TradingEnabled();
		}

    // While tradingEnabled is false, this function blocks all token transfers except:
    //   - Minting (from == address(0))
    //   - Transfers from the contract owner
    //   - Transfers from launchWallet or marketingWallet
    // Once tradingEnabled is true, this restriction no longer applies

		function _update(
			address from,
			address to,
			uint256 amount
		) internal virtual override {
			if (!tradingEnabled) {
				bool isMinting = from == address(0);
				bool isWhitelistedSender =
					from == owner() ||
					from == launchWallet ||
					from == marketingWallet;

				require(isMinting || isWhitelistedSender, "Trading is not yet enabled");
			}

	// Calls ERC20 logic to update balances and emit transfer events
			super._update(from, to, amount);
		}

    // A function to renounce (revoke) contract ownership for community safety. 
    // This action is irreversible and should not be called until an audit is complete.
		function finalizeContract() external onlyOwner {
			renounceOwnership();
		}
}
