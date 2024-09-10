window.addEventListener('DOMContentLoaded', function () {
    const token = localStorage.getItem("token");
    const cartProductId = localStorage.getItem("cartProductId");

    const productIdInput = document.querySelector("input[name='productId']");
    productIdInput.value = cartProductId;

    const form = document.querySelector("form");

    // Handle adding a single cart item
    form.addEventListener('submit', async function (event) {
        event.preventDefault();

        const productId = productIdInput.value;
        const quantity = document.querySelector("input[name='quantity']").value;

        try {
            const response = await fetch('/carts/addSingle', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ productId, quantity })
            });

            if (response.ok) {
                alert('Item added to cart successfully!');
                // Optionally, clear the form or redirect to the cart page
                form.reset();
            } else {
                const errorData = await response.json();
                alert(`Error: ${errorData.error}`);
            }
        } catch (error) {
            alert(`Error: ${error.message}`);
        }
    });

    // Handle adding multiple cart items
    document.getElementById('submitCartItems').addEventListener('click', async function () {
        const productIds = document.getElementById('productId').value.split(',');
        const quantities = document.getElementById('quantity').value.split(',');

        if (productIds.length !== quantities.length) {
            alert('The number of Product IDs and Quantities must match.');
            return;
        }

        const cartItems = productIds.map((id, index) => ({
            productId: parseInt(id.trim()),
            quantity: parseInt(quantities[index].trim())
        }));

        try {
            const response = await fetch('/carts/addMultiple', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ cartItemsList: cartItems })
            });

            if (response.ok) {
                alert('Cart items added successfully!');
                // Optionally, clear the form or redirect to the cart page
                form.reset();
            } else {
                const errorData = await response.json();
                alert(`Error: ${errorData.error}`);
            }
        } catch (error) {
            alert(`Error: ${error.message}`);
        }
    });
});
