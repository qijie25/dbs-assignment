const { EMPTY_RESULT_ERROR, UNIQUE_VIOLATION_ERROR, DUPLICATE_TABLE_ERROR } = require('../errors');
const reviewsModel = require('../models/reviews');

module.exports.create = function (req, res) {
    const memberId = req.body.memberId;
    const productId = req.body.productId;
    const orderId = req.body.orderId;
    const rating = req.body.rating;
    const reviewText = req.body.reviewText;

    return reviewsModel
        .create(memberId, productId, orderId, rating, reviewText)
        .then(function () {
            return res.sendStatus(201);
        })
        .catch(function (error) {
            console.error(error);
            if (error instanceof UNIQUE_VIOLATION_ERROR) {
                return res.status(400).json({ error: error.message });
            }
            return res.status(500).json({ error: error.message });
        });
}

module.exports.retrieveAll = function (req, res) {
    const memberId = res.locals.member_id;
    console.log('Member ID:', memberId);

    return reviewsModel
        .retrieveAll(memberId)
        .then(function (reviews) {
            console.log(reviews);
            return res.json({ reviews: reviews });
        })
        .catch(function (error) {
            console.error(error);
            return res.status(500).json({ error: error.message });
        });
}

module.exports.retrieveById = function (req, res) {
    const id = parseInt(req.params.id);
    const memberId = parseInt(res.locals.member_id);

    return reviewsModel
        .retrieveById(id, memberId)
        .then(function (review) {
            return res.json({ review });
        })
        .catch(function (error) {
            console.error(error);
            if (error instanceof EMPTY_RESULT_ERROR) {
                return res.status(404).json({ error: error.message });
            }
            return res.status(500).json({ error: error.message });
        });
}

module.exports.updateById = function (req, res) {
    const reviewId = req.params.id;
    const rating = req.body.rating;
    const reviewText = req.body.reviewText;
    return reviewsModel
        .updateById(reviewId, rating, reviewText)
        .then(function () {
            console.log("update ok!");
            return res.status(200).json({ msg: "updated!" });
        })
        .catch(function (error) {
            console.error(error);
            if (error instanceof EMPTY_RESULT_ERROR) {
                return res.status(404).json({ error: error.message });
            }
            return res.status(500).json({ error: error.message });
        });
}

module.exports.deleteById = function (req, res) {
    // Delete review by id
    const id = req.params.id;
    return reviewsModel
        .deleteById(id)
        .then(function () {
            console.log("delete ok!");
            return res.status(200).json({ msg: "deleted!" });
        })
        .catch(function (error) {
            console.error(error);
            if (error instanceof EMPTY_RESULT_ERROR) {
                // return res.status(404).json({ error: error.message });
                return res.status(404).json({ error: "No such review!" });
            }
            return res.status(500).json({ error: error.message });
        });
}
