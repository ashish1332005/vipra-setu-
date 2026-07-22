const CategoryConfig = require('../models/CategoryConfig');
const asyncHandler = require('../utils/asyncHandler');
const ensureDefaultCategories = require('../utils/ensureDefaultCategories');

const listPublicCategories = asyncHandler(async (req, res) => {
  await ensureDefaultCategories();
  const categories = await CategoryConfig.find({ isActive: true }).sort('name');
  res.json({ categories });
});

module.exports = { listPublicCategories };
