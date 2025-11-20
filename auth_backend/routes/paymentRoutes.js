const express = require('express');
const router = express.Router();

const stripeSecret = process.env.STRIPE_SECRET_KEY;

if (!stripeSecret) {
  console.warn('⚠️  STRIPE_SECRET_KEY is not set. Payment endpoints will fail until it is configured in auth_backend/.env');
}

const stripe = require('stripe')(stripeSecret || 'sk_test_REPLACE_ME');

router.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency = 'usd', metadata } = req.body;

    // Create a PaymentIntent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // amount in cents
      currency: currency,
      metadata: metadata || {},
      automatic_payment_methods: {
        enabled: true,
      },
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (error) {
    console.error('Error creating payment intent:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;