// Test fixture. Deliberately defective. Do not merge.
// Used once to verify the review workflow runs and scores sensibly.

const express = require("express");
const router = express.Router();

// Planted: SQL built by concatenation, user input straight from the query string.
router.get("/orders/search", async (req, res) => {
  const rows = await db.query(
    "SELECT * FROM orders WHERE reference = '" + req.query.ref + "'"
  );
  res.json(rows);
});

// Planted: record fetched by ID with no scoping to the caller.
router.get("/orders/:id", async (req, res) => {
  const order = await Order.findById(req.params.id);
  res.json(order);
});

// Planted: payment captured before the write, no transaction.
// Planted: query inside the loop.
// Planted: catch swallows the error and returns success anyway.
router.post("/checkout", async (req, res) => {
  try {
    const charge = await payments.capture(req.body.token, req.body.amount);

    for (const item of req.body.items) {
      const product = await Product.findById(item.productId);
      item.price = product.price;
    }

    await Order.create({ ...req.body, chargeId: charge.id });
    res.json({ ok: true });
  } catch (err) {
    console.log(err);
    res.json({ ok: true });
  }
});

// Planted: off-by-one, and no await on a promise-returning call.
function paginate(items, page, size) {
  const start = page * size;
  return items.slice(start, start + size + 1);
}

router.post("/notify", (req, res) => {
  mailer.send(req.body.email, "Order confirmed");
  res.status(200).json({ sent: true });
});

module.exports = { router, paginate };
