window.addEventListener('DOMContentLoaded', function () {
    const token = localStorage.getItem("token");

    fetchAgeGroupSpending();

    const form = document.querySelector("form");
    const button = document.querySelector("button");

    function fetchAgeGroupSpending(queryParams = "") {
        fetch(`/dashboard/ageGroupSpending?${queryParams}`, {
            headers: {
                Authorization: `Bearer ${token}`
            }
        })
            .then(function (response) {
                return response.json();
            })
            .then(function (body) {
                if (body.error) throw new Error(body.error);
                const spendings = body.spendings;
                console.log("Spendings received from server:", spendings); // Debug log
                const tbody = document.querySelector("#spending-tbody");
                tbody.innerHTML = '';
                spendings.forEach(function (spending) {
                    const row = document.createElement("tr");

                    const ageGroupCell = document.createElement("td");
                    const totalSpendingCell = document.createElement("td");
                    const numberOfMembersCell = document.createElement("td");
                    ageGroupCell.textContent = spending.agegroup;
                    totalSpendingCell.textContent = spending.totalspending;
                    numberOfMembersCell.textContent = spending.numofmembers;

                    row.appendChild(ageGroupCell);
                    row.appendChild(totalSpendingCell);
                    row.appendChild(numberOfMembersCell);

                    tbody.appendChild(row);
                });
            })
            .catch(function (error) {
                console.error("Error fetching age group spending:", error); // Debug log
            });
    }

    function handleFormSubmission(event) {
        event.preventDefault();

        const gender = form.elements.gender.value;
        const minTotalSpending = form.elements.minTotalSpending.value;
        const minMemberTotalSpending = form.elements.minMemberTotalSpending.value;
        const queryParams = new URLSearchParams({
            gender,
            minTotalSpending,
            minMemberTotalSpending
        }).toString();

        fetchAgeGroupSpending(queryParams);
    }

    button.addEventListener("click", handleFormSubmission);
});
