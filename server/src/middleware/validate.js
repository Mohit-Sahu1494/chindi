const { sendError } = require('../utils/apiResponse');

function validate(schema, source = 'body') {
  return async (req, res, next) => {
    try {
      const parsed = await schema.parseAsync(req[source]);
      req[source] = parsed;
      next();
    } catch (err) {
      if (err.errors) {
        const formattedErrors = err.errors.map(e => ({
          field: e.path.join('.'),
          message: e.message,
        }));
        const summaryMessage = formattedErrors.map(e => e.message).join('. ');
        return sendError(res, summaryMessage || 'Validation error', 400, formattedErrors);
      }
      return sendError(res, err.message, 400);
    }
  };
}

module.exports = {
  validate,
};
