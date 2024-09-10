window.addEventListener('DOMContentLoaded', function () {
    const token = localStorage.getItem("token");

    fetchSaleOrders();

    const form = document.querySelector("form");
    const button = document.querySelector("button");

    function fetchSaleOrders(queryParams = "") {
        fetch(`/saleOrders?${queryParams}`, {
            headers: {
                Authorization: `Bearer ${token}`,
            },
        })
            .then(function (response) {
                return response.json();
            })
            .then(function (body) {
                if (body.error) throw new Error(body.error);
                const saleOrderItems = body.saleOrderItems;
                const tbody = document.querySelector("#product-tbody");
                tbody.innerHTML = "";
                saleOrderItems.forEach(function (item) {
                    const row = document.createElement("tr");
                    row.classList.add("product");

                    const nameCell = document.createElement("td");
                    const descriptionCell = document.createElement("td");
                    const unitPriceCell = document.createElement("td");
                    const quantityCell = document.createElement("td");
                    const countryCell = document.createElement("td");
                    const imageUrlCell = document.createElement("td");
                    const orderIdCell = document.createElement("td");
                    const orderDatetimeCell = document.createElement("td");
                    const statusCell = document.createElement("td");
                    const productTypeCell = document.createElement("td");
                    const memberUsernameCell = document.createElement("td");

                    nameCell.textContent = item.name;
                    descriptionCell.textContent = item.description;
                    unitPriceCell.textContent = item.unitPrice;
                    quantityCell.textContent = item.quantity;
                    countryCell.textContent = item.country;
                    imageUrlCell.innerHTML = `<img src="${item.imageUrl}" alt="Product Image">`;
                    orderIdCell.textContent = item.saleOrderId;
                    orderDatetimeCell.textContent = new Date(item.orderDatetime).toLocaleString();
                    statusCell.textContent = item.status;
                    productTypeCell.textContent = item.productType;
                    memberUsernameCell.textContent = item.username;

                    row.appendChild(nameCell);
                    row.appendChild(descriptionCell);
                    row.appendChild(imageUrlCell);
                    row.appendChild(unitPriceCell);
                    row.appendChild(quantityCell);
                    row.appendChild(countryCell);
                    row.appendChild(orderIdCell);
                    row.appendChild(orderDatetimeCell);
                    row.appendChild(statusCell);
                    row.appendChild(productTypeCell);
                    row.appendChild(memberUsernameCell);
                    tbody.appendChild(row);
                });
            })
            .catch(function (error) {
                console.error(error);
            });
    }

    function handleFormSubmission(event) {
        event.preventDefault();

        const formElements = Array.from(form.elements);
        const formValues = formElements.reduce(function (values, element) {
            if (element.type !== "submit" && element.value !== "") {
                values[element.name] = element.value;
            }
            return values;
        }, {});

        const status = Array.from(form.elements.status.options)
            .filter(function (option) {
                return option.selected;
            })
            .map(function (option) {
                return option.value;
            });

        const queryParams = new URLSearchParams({
            ...formValues,
            status: status.join(','),
        }).toString();

        fetchSaleOrders(queryParams);
    }

    button.addEventListener("click", handleFormSubmission);
});
