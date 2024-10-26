<script>
    import { onMount } from 'svelte';
    //import { ethers } from 'ethers'; // Import ethers.js

    let notaries = [];

    const provider = new ethers.JsonRpcProvider(rpcURL, {
        chainId: Number(chainID),
        name: 'banksy'
    });

    const notaryCaller = new ethers.Contract(currentTokenInstance.contractAddress, [
        "function getNotaryList(uint256 tokenId) public view returns (tuple(bytes32 notaryHash, uint256 timestamp)[])"
    ], provider);

    async function getNotaryData() {
        return await notaryCaller.getNotaryList(currentTokenInstance.tokenId);
    }

    onMount(async () => {
        const fetchedNotaries = await getNotaryData();
        console.log(`NOTARYDATA: ${fetchedNotaries}`);
        notaries = fetchedNotaries.map(notary => ({
            hash: `${notary[0]}`.substring(0, 16) + '...', // Abbreviate hash
            timestamp: new Date(Number(BigInt(notary[1])) * 1000).toLocaleString() // Convert to human-readable format
        }));
    });
</script>

<style>
    body {
        font-family: Arial, sans-serif;
        margin: 20px;
    }

    table {
        width: 100%;
        border-collapse: collapse;
    }

    th,
    td {
        border: 1px solid #ddd;
        padding: 8px;
        text-align: left;
    }

    th {
        background-color: #f2f2f2;
    }
</style>

<h1>Notary List</h1>
<br>
<table>
    <thead>
        <tr>
            <th>Notary Hash</th>
            <th>Timestamp</th>
        </tr>
    </thead>
    <tbody>
        {#each notaries as notary}
            <tr>
                <td>{notary.hash}</td>
                <td>{notary.timestamp}</td>
            </tr>
        {/each}
    </tbody>
</table>