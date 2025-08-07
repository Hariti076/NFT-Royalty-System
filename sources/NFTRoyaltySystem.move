module message_board_addr::NFTRoyalty {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    
    struct NFTRoyalty has store, key {
        creator: address,           
        royalty_percentage: u64,   
        total_sales: u64,          
        total_royalties: u64,     
    }

    
    struct NFTOwnership has store, key {
        current_owner: address,     
        purchase_price: u64,      
    }

   
    public fun mint_nft_with_royalty(
        creator: &signer, 
        royalty_percentage: u64
    ) {
        let creator_addr = signer::address_of(creator);
        
        
        let nft_royalty = NFTRoyalty {
            creator: creator_addr,
            royalty_percentage,
            total_sales: 0,
            total_royalties: 0,
        };
        
        
        let nft_ownership = NFTOwnership {
            current_owner: creator_addr,
            purchase_price: 0,
        };
        
        move_to(creator, nft_royalty);
        move_to(creator, nft_ownership);
    }

    public fun secondary_sale(
        buyer: &signer, 
        nft_creator: address, 
        sale_price: u64
    ) acquires NFTRoyalty, NFTOwnership {
        let buyer_addr = signer::address_of(buyer);
        
        
        let royalty_info = borrow_global_mut<NFTRoyalty>(nft_creator);
        let ownership_info = borrow_global_mut<NFTOwnership>(nft_creator);
        
        
        let royalty_amount = (sale_price * royalty_info.royalty_percentage) / 100;
        let seller_amount = sale_price - royalty_amount;
        
        let payment = coin::withdraw<AptosCoin>(buyer, sale_price);
        
        let royalty_payment = coin::extract(&mut payment, royalty_amount);
        coin::deposit<AptosCoin>(royalty_info.creator, royalty_payment);
        
        coin::deposit<AptosCoin>(ownership_info.current_owner, payment);
        
        ownership_info.current_owner = buyer_addr;
        ownership_info.purchase_price = sale_price;
        royalty_info.total_sales = royalty_info.total_sales + 1;
        royalty_info.total_royalties = royalty_info.total_royalties + royalty_amount;
    }

}

