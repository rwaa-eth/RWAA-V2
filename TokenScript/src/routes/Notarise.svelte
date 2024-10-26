<script>
    import { onMount } from 'svelte';
    let fileInput;
    let result = '';

    const handleSubmit = async (event) => {
        event.preventDefault(); // Prevent the default form submission

        const formData = new FormData();
        formData.append('file', fileInput.files[0]);

        try {
            const response = await fetch('https://scriptproxy.smarttokenlabs.com:8086/register-file', {
                method: 'POST',
                body: formData,
            });

            if (!response.ok) {
                throw new Error('Network response was not ok');
            }

            const data = await response.json();
            console.log('File hash:', data.data); // Log the hash received from the server
            result = `File hash: ${data.data}`;

            // Assuming web3.action.setProps is available in your context
            web3.action.setProps({
                docHash: data.data
            });

        } catch (error) {
            console.error('Error uploading file:', error);
            result = 'Error uploading file. Please try again.';
        }
    };
</script>

<style>
    body {
        font-family: Arial, sans-serif;
        margin: 20px;
    }

    input[type="file"] {
        margin-bottom: 10px;
    }

    button {
        padding: 10px 15px;
        background-color: #4CAF50;
        color: white;
        border: none;
        cursor: pointer;
    }

    button:hover {
        background-color: #45a049;
    }
</style>

<h1>Upload a File</h1>
<form on:submit={handleSubmit}>
    <input type="file" bind:this={fileInput} name="file" required>
    <button type="submit">Upload</button>
</form>
<div>{result}</div>