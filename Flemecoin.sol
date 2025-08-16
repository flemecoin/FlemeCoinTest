// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Importing industry-standard contracts for ERC20 functionality, ownership control, and security:
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Flemecoin is ERC20, ERC20Burnable, Ownable {

/*
HERE CORE COMPONENTS ARE DECLARED: 
*/
    
	// Defines wallets used. 
	// Distribution amounts are defined further down the contract: 
		address public immutable launchWallet;       // Used to populate the DEX liquidity pool; also receives contract ownership.
		address public immutable marketingWallet;    // Marketing Funds (90% will be escrowed via Team Finance). 
		address public immutable devWallet;          // Dev funds (100% will be escrowed via Team Finance).    

	// Creates a timestamp variable for when trading is manually enabled:
		uint256 public tradeEnabledTimestamp;

	// Allows trading to be enabled as a one-time event:
		bool public tradingEnabled = false;
		event TradingEnabled(uint256 enabledAt);

	// Defines the total token supply 1,000,000,000 with 18 decimal places:
		uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18;

/*
HERE THE COMPONENTS ARE ASSEMBLED:
*/

	// Using constructor(), wallet addresses are requested when the contract is deployed:
		constructor(
			address _launchWallet,
			address _marketingWallet,
			address _devWallet
	// Token is named and symbol assigned; contract ownership is transferred to launchWallet: 
		) ERC20("Flemecoin", "FLEME") Ownable(_launchWallet) {
        
	// Ensures all wallet addresses are populated at deployment:
        require(_launchWallet != address(0), "Launch wallet cannot be zero address");
        require(_devWallet != address(0), "Dev wallet cannot be zero address");
        require(_marketingWallet != address(0), "Marketing wallet cannot be zero address");

    // Assign wallets:
        launchWallet = _launchWallet;
        devWallet = _devWallet;
        marketingWallet = _marketingWallet;

	// Mints initial token supply to designated wallets:
        _mint(launchWallet, 870_000_000 * 10**18);      // 870M for the initial DEX liquidity pool 
        _mint(devWallet, 30_000_000 * 10**18);          // 30M dev funds, will be escrowed via Team Finance
        _mint(marketingWallet, 100_000_000 * 10**18);   // 10M available at launch, 90M will be escrowed via Team Finance

    // Sanity check: ensure total minted supply equals the defined max supply:
        assert(totalSupply() == MAX_SUPPLY);
    }

    // This function enables trading as a one-time event.
    // Once enabled, it cannot be changed (there is no disable function).
		function enableTrading() external onlyOwner {
			require(!tradingEnabled, "Trading already enabled");
			tradingEnabled = true;
			tradeEnabledTimestamp = block.timestamp;

	// Record when trading is enabled:
			emit TradingEnabled(tradeEnabledTimestamp);
		}

    // While tradingEnabled is false, this function blocks all token transfers except:
    //   - Minting (from == address(0))
    //   - Transfers from the contract owner
    //   - Transfers from launchWallet, marketingWallet, or devWallet
    // This is necessary to allow the LP and escrows to be created. 
    // Once tradingEnabled is true, this restriction no longer applies.
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
					from == marketingWallet ||
					from == devWallet;

				require(isMinting || isWhitelistedSender, "Trading is not yet enabled");
			}

	// Calls ERC20 logic to update balances and emit transfer events:
			super._update(from, to, amount);
		}

    // A function to renounce (revoke) contract ownership for community safety.
    // Can only be called after trading is enabled. This action is irreversible: 
		function finalizeContract() external onlyOwner {
			require(tradingEnabled, "Enable trading first");
			renounceOwnership();
		}
}
