const { sendSuccess, sendError } = require('../utils/apiResponse');

// In-memory version state initialized from environment variables
let currentVersionState = {
  latestVersion: process.env.LATEST_APP_VERSION || '1.0.1',
  latestVersionCode: parseInt(process.env.LATEST_VERSION_CODE || '2', 10),
  minRequiredVersionCode: parseInt(process.env.MIN_REQUIRED_VERSION_CODE || '1', 10),
  updateUrl: process.env.APP_UPDATE_URL || 'https://github.com/mohit-sahu/chindi/releases/latest',
  title: process.env.APP_UPDATE_TITLE || 'Naya Update Uplabdh Hai! 🚀',
  releaseNotes:
    process.env.APP_RELEASE_NOTES ||
    'Naye features, calculations me sudhar aur fast performance ke sath naya update uplabdh hai.',
  forceUpdate: process.env.FORCE_UPDATE === 'true',
};

/**
 * Returns latest app version information
 */
async function getLatestAppVersion(req, res, next) {
  try {
    return sendSuccess(res, currentVersionState, 'Version details retrieved successfully');
  } catch (error) {
    next(error);
  }
}

/**
 * Updates app version information dynamically (Admin)
 */
async function updateAppVersion(req, res, next) {
  try {
    const {
      latestVersion,
      latestVersionCode,
      minRequiredVersionCode,
      updateUrl,
      title,
      releaseNotes,
      forceUpdate,
    } = req.body;

    currentVersionState = {
      ...currentVersionState,
      ...(latestVersion && { latestVersion: latestVersion.trim() }),
      ...(latestVersionCode && { latestVersionCode: parseInt(latestVersionCode, 10) }),
      ...(minRequiredVersionCode && { minRequiredVersionCode: parseInt(minRequiredVersionCode, 10) }),
      ...(updateUrl && { updateUrl: updateUrl.trim() }),
      ...(title && { title: title.trim() }),
      ...(releaseNotes && { releaseNotes: releaseNotes.trim() }),
      ...(typeof forceUpdate === 'boolean' && { forceUpdate }),
    };

    return sendSuccess(res, currentVersionState, 'App version updated successfully');
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getLatestAppVersion,
  updateAppVersion,
};
