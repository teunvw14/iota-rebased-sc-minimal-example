<script lang="ts">
    import type { Wallet, WalletAccount } from '@mysten/wallet-standard';
    import { getWallets } from '@mysten/wallet-standard';
    import { getFullnodeUrl, IotaClient } from '@iota/iota-sdk/client';
    import { Transaction } from '@iota/iota-sdk/transactions';
    
    
    let PACKAGE_ID = "0x634b32738b06f52131d4e01429a0d27e78817b8e2f13fbb375b9cab7cb0fbbc4";
    let MODULE_NAME = "confirmed_whale_nft";
    let FUNCTION_NAME = "confirm_whale";
    let GAS_BUDGET = 100_000_000;
    
    let activeWallet = $state(null);
    let activeWalletAccount = $state(null);
    let activeWalletAccountBalance = $state(0);
    let sendAmountNanos = $state(0);
    let resultText = $state("");
    let explorerUrl = $state("");
    
    const iotaClient = new IotaClient({ url: getFullnodeUrl('testnet') });

    async function connectWallet() {
        let wallets = getWallets().get();
        if (wallets.length == 0) {
            console.log("No wallets found to connect to. Make sure you installed an IOTA web wallet.");
            return;
        }
        // Make sure we get the right wallet
        activeWallet = wallets.find((w) => w.name == "IOTA Wallet");
        if (!activeWallet) {
            console.log("No IOTA wallets found to connect to. Make sure you installed an IOTA web wallet.");
            return;
        }
        activeWallet.features['standard:connect'].connect();
        activeWallet.features['standard:events'].on("change", () => {
            activeWalletAccount = activeWallet.accounts[0];
            updateBalance();
        });
    }

    // Helper function to update the balance of the activeWalletAccount
    async function updateBalance() {
        if (activeWalletAccount) {
            activeWalletAccountBalance = (await iotaClient.getBalance({owner: activeWalletAccount.address})).totalBalance;
        }
    }

    // Send a transaction to the smart contract, calling `confirm_whale`.
    async function confirmWhale() {

        // Set up the transaction
        let tx = new Transaction();
        tx.setGasBudget(GAS_BUDGET);

        let [coin] = tx.splitCoins(tx.gas, [sendAmountNanos]);
        tx.moveCall({
            package: PACKAGE_ID,
            module: MODULE_NAME,
            function: FUNCTION_NAME,
            arguments: [tx.object(coin)],
        });

        // Request the wallet to sign the transaction
        let {bytes, signature} = 
        await (activeWallet.features['iota:signTransaction']).signTransaction({
            transaction: tx, 
            account: activeWalletAccount,
        });
    
        // Send signed transaction to the network for execution
        let transactionResult = await iotaClient.executeTransactionBlock({
            transactionBlock: bytes,
            signature: signature,
        })

        // Wait for transaction to complete and parse results
        await iotaClient.waitForTransaction({ digest: transactionResult.digest });

        let transactionBlock = await iotaClient.getTransactionBlock({
            digest: transactionResult.digest,
            options: {
                showEffects: true,
                showObjectChanges: true,
            }
        });

        // Show transaction results, if the transaction was successful
        if (transactionBlock.effects?.status.status == 'success'){
            let confirmedWhaleNftCreated = transactionBlock.objectChanges?.find((change) => {
                return change.objectType.endsWith("::confirmed_whale_nft::ConfirmedWhaleNFT")
            });
            if (confirmedWhaleNftCreated) {
                resultText = `Transaction success! ConfirmedWhaleNFT was created with id ${confirmedWhaleNftCreated.objectId}.`;
                explorerUrl = `https://explorer.rebased.iota.org/object/${confirmedWhaleNftCreated.objectId}`;
            } else {
                resultText = "Transaction succeeded, but ConfirmedWhaleNFT was not created.";
            }
        }
    }
</script>

<div class="m-4">

<h1>
    Welcome to the Confirmed Whale dApp!
</h1>

<button 
    onclick={connectWallet}
    class="bg-blue-500 p-2"
>
    {activeWallet ? 'Connected' : 'Connect wallet'}
</button>

<p>{activeWalletAccount ? `Balance: ${activeWalletAccountBalance}` : 'Connect a wallet to show balance'}</p>

<hr/>

<h3>Send amount (need at least 5000000000 to get ConfirmedWhaleNFT)</h3>
<input bind:value={sendAmountNanos} type="number" lang="en" step="1"/>

<button 
    onclick={confirmWhale}
    class="bg-blue-500 p-2"
    disabled={!activeWalletAccount}
>
    {activeWalletAccount ? "call confirm_whale" : "Connect a wallet to interact with smart contract."}
</button>

<p>{resultText}</p>
<a 
    href={explorerUrl} target="_blank"
    class="bg-green-300"
>
    {explorerUrl == "" ? "" : "Check out the NFT on the IOTA Rebased explorer"}
</a>

</div>