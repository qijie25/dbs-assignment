function fetchReview(reviewId) {
    const token = localStorage.getItem('token');

    fetch(`/reviews/${reviewId}`, {
        headers: {
            Authorization: `Bearer ${token}`
        }
    })
    .then(function (response) {
        if (!response.ok) {
            throw new Error('Review not found');
        }
        return response.json();
    })
    .then(function (body) {
        const review = body.review;
        const reviewContainerDiv = document.querySelector('#review-container');
        reviewContainerDiv.innerHTML = '';

        const reviewDiv = document.createElement('div');
        reviewDiv.classList.add('review-row');

        let ratingStars = '';
        for (let i = 0; i < review.rating; i++) {
            ratingStars += '⭐';
        }

        reviewDiv.innerHTML = `
            <h3>Review ID: ${review.id}</h3>
            <p>Product Name: ${review.productName}</p>
            <p>Rating: ${ratingStars}</p>
            <p>Review Text: ${review.reviewtext}</p>
            <p>Review Date: ${review.reviewdate ? review.reviewdate.slice(0, 10) : ""}</p>
        `;

        reviewContainerDiv.appendChild(reviewDiv);
    })
    .catch(function (error) {
        console.error(error);
        const reviewContainerDiv = document.querySelector('#review-container');
        reviewContainerDiv.innerHTML = `<p>${error.message}</p>`;
    });
}

document.addEventListener('DOMContentLoaded', function () {
    const form = document.querySelector('#review-form');
    form.addEventListener('submit', function (event) {
        event.preventDefault();
        const reviewId = document.querySelector('#reviewId').value;
        fetchReview(reviewId);
    });
});