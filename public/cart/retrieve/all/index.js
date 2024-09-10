

function fetchCartItems(token) {
    return fetch('/carts', {
        headers: {
            Authorization: `Bearer ${token}`
        }
    })
    .then(function (response) {
        return response.json();
    })
    .then(function (body) {
        if (body.error) throw new Error(body.error);
        const cartItems = body.cartItems;
        const tbody = document.querySelector("#cart-items-tbody");
        tbody.innerHTML = ""; // Clear existing rows
        cartItems.forEach(function (cartItem) {
            const row = document.createElement("tr");
            row.classList.add("product");

            const descriptionCell = document.createElement("td");
            const countryCell = document.createElement("td");
            const quantityCell = document.createElement("td");
            const unitPriceCell = document.createElement("td");
            const subTotalCell = document.createElement("td");
            const updateButtonCell = document.createElement("td");
            const deleteButtonCell = document.createElement("td");
            const checkboxCell = document.createElement("td");

            const updateButton = document.createElement("button");
            const deleteButton = document.createElement("button");
            const checkbox = document.createElement("input");
            checkbox.type = "checkbox";
            checkbox.value = cartItem.id;
            checkbox.dataset.id = cartItem.id;

            descriptionCell.textContent = cartItem.product.description;
            countryCell.textContent = cartItem.product.country;
            unitPriceCell.textContent = cartItem.product.unitPrice;
            subTotalCell.textContent = (cartItem.product.unitPrice * cartItem.quantity).toFixed(2);

            const quantityInput = document.createElement("input");
            quantityInput.type = "number";
            quantityInput.value = cartItem.quantity;
            quantityInput.addEventListener("input", function () {
                this.value = this.value.replace(/[^0-9]/g, "");
            });
            quantityCell.appendChild(quantityInput);

            updateButton.textContent = "Update";
            deleteButton.textContent = "Delete";

            updateButton.addEventListener("click", function () {
                const updatedQuantity = quantityInput.value;
                const updatedCartItem = {
                    quantity: Number(updatedQuantity),
                    productId: cartItem.productId // Add the missing value for 'productId'
                };

                fetch(`/carts/${cartItem.id}`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json',
                        Authorization: `Bearer ${token}`
                    },
                    body: JSON.stringify(updatedCartItem)
                })
                .then(function (response) {
                    return response.json().then(function(data) {
                        if (response.ok) {
                            alert("Update successful!");
                        } else {
                            alert("Update failed: " + data.error);
                        }
                        setTimeout(function() {
                            location.reload();
                        }, 1000);
                    });
                })
                .catch(function (error) {
                    console.error(error);
                    alert("An error occurred: " + error.message);
                });
            });

            deleteButton.addEventListener("click", function () {
                fetch(`/carts/${cartItem.id}`, {
                    method: 'DELETE',
                    headers: {
                        Authorization: `Bearer ${token}`
                    }
                })
                .then(function (response) {
                    return response.json();
                })
                .then(function (body) {
                    if (body.error) throw new Error(body.error);
                    alert('Item deleted successfully!');
                    
                    setTimeout(function() {
                        fetchCartItems(token);
                    }, 1000);
                })
                .catch(function (error) {
                    console.error(error);
                    alert('Failed to delete item: ' + error.message);
                });
            });            

            updateButtonCell.appendChild(updateButton);
            deleteButtonCell.appendChild(deleteButton);
            checkboxCell.appendChild(checkbox);

            row.appendChild(checkboxCell);
            row.appendChild(descriptionCell);
            row.appendChild(countryCell);
            row.appendChild(unitPriceCell);
            row.appendChild(subTotalCell);
            row.appendChild(quantityCell);
            row.appendChild(updateButtonCell);
            row.appendChild(deleteButtonCell);

            tbody.appendChild(row);
        });
    })
    .catch(function (error) {
        console.error(error);
    });
}

function updateMultipleCartItems(token) {
    const selectedItems = [];
    const rows = document.querySelectorAll("#cart-items-tbody tr");

    rows.forEach(function (row) {
        const checkbox = row.querySelector("input[type='checkbox']");
        if (checkbox.checked) {
            const id = parseInt(checkbox.dataset.id);
            const quantity = parseInt(row.querySelector("input[type='number']").value);
            if (!isNaN(id) && !isNaN(quantity)) {
                selectedItems.push({ id, quantity });
            }
        }
    });

    fetch(`/carts/updateMultiple`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({ cartItems: selectedItems })
    })
    .then(function (response) {
        return response.json();
    })
    .then(function (body) {
        if (body.error) throw new Error(body.error);
        console.log(body.msg);
        fetchCartItems(token)
            .then(function () {
                return fetchCartSummary(token);
            });
    })
    .catch(function (error) {
        console.error(error);
    });
}


function fetchCartSummary(token) {
    return fetch('/carts/summary', {
        headers: {
            Authorization: `Bearer ${token}`
        }
    })
    .then(function (response) {
        return response.json();
    })
    .then(function (body) {
        if (body.error) throw new Error(body.error);
        const cartSummary = body.cartSummary;
        const cartSummaryDiv = document.querySelector("#cart-summary");
        cartSummaryDiv.innerHTML = ""; // Clear existing content
        const cartSummaryLabel1 = document.createElement("label");
        cartSummaryLabel1.textContent = "Total Quantity: ";
        cartSummaryLabel1.classList.add("label");
        const cartSummaryValue1 = document.createElement("span");
        cartSummaryValue1.textContent = cartSummary.totalQuantity;
        cartSummaryValue1.classList.add("value");
        const cartSummaryLabel2 = document.createElement("label");
        cartSummaryLabel2.textContent = "Total Checkout Price: ";
        cartSummaryLabel2.classList.add("label");
        const cartSummaryValue2 = document.createElement("span");
        cartSummaryValue2.textContent = cartSummary.totalPrice;
        cartSummaryValue2.classList.add("value");
        const cartSummaryLabel3 = document.createElement("label");
        cartSummaryLabel3.textContent = "Total Unique Products: ";
        cartSummaryLabel3.classList.add("label");
        const cartSummaryValue3 = document.createElement("span");
        cartSummaryValue3.textContent = cartSummary.totalProduct;
        cartSummaryValue3.classList.add("value");

        cartSummaryDiv.appendChild(cartSummaryLabel1);
        cartSummaryDiv.appendChild(cartSummaryValue1);
        cartSummaryDiv.appendChild(document.createElement("br"));
        cartSummaryDiv.appendChild(cartSummaryLabel2);
        cartSummaryDiv.appendChild(cartSummaryValue2);
        cartSummaryDiv.appendChild(document.createElement("br"));
        cartSummaryDiv.appendChild(cartSummaryLabel3);
        cartSummaryDiv.appendChild(cartSummaryValue3);
    })
    .catch(function (error) {
        console.error(error);
    });
}

window.addEventListener('DOMContentLoaded', function () {
    const token = localStorage.getItem("token");
    fetchCartItems(token)
        .then(function () {
            return fetchCartSummary(token);
        });

    document.getElementById("bulk-update").addEventListener("click", function () {
        updateMultipleCartItems(token);
    });
});
