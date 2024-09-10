const express = require('express');
const cartController = require('../controllers/cartsController');
const jwtMiddleware = require('../middleware/jwtMiddleware');

const router = express.Router();

// All routes in this file will use the jwtMiddleware to verify the token and check if the user is an admin.
// Here the jwtMiddleware is applied at the router level to apply to all routes in this file
// But you can also apply the jwtMiddleware to individual routes
// router.use(jwtMiddleware.verifyToken, jwtMiddleware.verifyIsAdmin);

router.use(jwtMiddleware.verifyToken);

router.post('/addSingle', cartController.createSingleCartItem);
router.post('/addMultiple', cartController.createMultipleCartItems);
router.put('/:id', cartController.updateSingleCartItem);
router.put('/updateMultiple', cartController.updateMultipleCartItems);
router.delete('/:id', cartController.deleteSingleCartItem);
// router.delete('/deleteMultiple', cartController.deleteMultipleCartItems);
router.get('/', cartController.getAllCartItems);
router.get('/summary', cartController.getCartSummary);

module.exports = router;