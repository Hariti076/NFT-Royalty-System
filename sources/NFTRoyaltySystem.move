module message_board_addr::NFTRoyalty {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    /// Struct representing an NFT with royalty information
    struct NFTRoyalty has store, key {
        creator: address,           // Original creator of the NFT
        royalty_percentage: u64,    // Royalty percentage (e.g., 10 = 10%)
        total_sales: u64,          // Total number of secondary sales
        total_royalties: u64,      // Total royalties collected
    }

    /// Struct to track NFT ownership
    struct NFTOwnership has store, key {
        current_owner: address,     // Current owner of the NFT
        purchase_price: u64,       // Last purchase price
    }

    /// Function to mint NFT with royalty settings
    public fun mint_nft_with_royalty(
        creator: &signer, 
        royalty_percentage: u64
    ) {
        let creator_addr = signer::address_of(creator);
        
        // Create NFT royalty structure
        let nft_royalty = NFTRoyalty {
            creator: creator_addr,
            royalty_percentage,
            total_sales: 0,
            total_royalties: 0,
        };
        
        // Create ownership structure
        let nft_ownership = NFTOwnership {
            current_owner: creator_addr,
            purchase_price: 0,
        };
        
        move_to(creator, nft_royalty);
        move_to(creator, nft_ownership);
    }

    /// Function to handle secondary sale with automatic royalty distribution
    public fun secondary_sale(
        buyer: &signer, 
        nft_creator: address, 
        sale_price: u64
    ) acquires NFTRoyalty, NFTOwnership {
        let buyer_addr = signer::address_of(buyer);
        
        // Get NFT royalty and ownership info
        let royalty_info = borrow_global_mut<NFTRoyalty>(nft_creator);
        let ownership_info = borrow_global_mut<NFTOwnership>(nft_creator);
        
        // Calculate royalty amount
        let royalty_amount = (sale_price * royalty_info.royalty_percentage) / 100;
        let seller_amount = sale_price - royalty_amount;
        
        // Transfer payment from buyer
        let payment = coin::withdraw<AptosCoin>(buyer, sale_price);
        
        // Distribute royalty to creator
        let royalty_payment = coin::extract(&mut payment, royalty_amount);
        coin::deposit<AptosCoin>(royalty_info.creator, royalty_payment);
        
        // Pay remaining amount to current owner (seller)
        coin::deposit<AptosCoin>(ownership_info.current_owner, payment);
        
        // Update NFT ownership and stats
        ownership_info.current_owner = buyer_addr;
        ownership_info.purchase_price = sale_price;
        royalty_info.total_sales = royalty_info.total_sales + 1;
        royalty_info.total_royalties = royalty_info.total_royalties + royalty_amount;
    }
}