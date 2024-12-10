/// Module: confirmed_whale_nft
module confirmed_whale_nft::confirmed_whale_nft {
    use iota::iota::{IOTA};
    use iota::coin::{Coin};

    public struct ConfirmedWhaleNFT has key {
        id: UID,
        owner: address
    }

    // Send a ConfirmedWhaleNFT to the caller if they send along a coin with at
    // least 5 IOTA.
    public fun confirm_whale(coin: Coin<IOTA>, ctx: &mut TxContext) {
        let coin_value_iota = coin.value() / 1_000_000_000;
        let caller = tx_context::sender(ctx);
        if (coin_value_iota >= 5) {
            let nft = ConfirmedWhaleNFT {
                id: object::new(ctx),
                owner: caller
            };
            transfer::transfer(nft, caller);
        };
        transfer::public_transfer(coin, caller);
    }
}