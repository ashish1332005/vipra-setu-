const CategoryConfig = require('../models/CategoryConfig');
const defaultCategories = require('../config/defaultCategories');

const mergeServiceTypes = (existing = [], defaults = []) => {
  const seen = new Set();
  return [...existing, ...defaults]
    .map((item) => String(item || '').trim())
    .filter((item) => item && !seen.has(item.toLowerCase()) && seen.add(item.toLowerCase()));
};

const ensureDefaultCategories = async () => {
  for (const category of defaultCategories) {
    const existing = await CategoryConfig.findOne({
      $or: [
        { defaultKey: category.defaultKey },
        { name: category.name },
      ],
    });

    if (existing) {
      let changed = false;
      if (!existing.defaultKey) {
        existing.defaultKey = category.defaultKey;
        changed = true;
      }
      if (!existing.description && category.description) {
        existing.description = category.description;
        changed = true;
      }
      const mergedServiceTypes = mergeServiceTypes(
        existing.serviceTypes,
        category.serviceTypes
      );
      if (mergedServiceTypes.length !== (existing.serviceTypes || []).length) {
        existing.serviceTypes = mergedServiceTypes;
        changed = true;
      }
      if (existing.isActive === false) {
        existing.isActive = true;
        changed = true;
      }
      if (changed) await existing.save();
      continue;
    }

    await CategoryConfig.create(category);
  }
};

module.exports = ensureDefaultCategories;
