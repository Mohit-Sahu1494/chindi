const { getLatestAppVersion, updateAppVersion } = require('../controllers/versionController');

describe('App Version Controller (In-App Update Engine)', () => {
  let req, res, next;

  beforeEach(() => {
    req = { body: {} };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    next = jest.fn();
  });

  test('returns current version information', async () => {
    await getLatestAppVersion(req, res, next);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        data: expect.objectContaining({
          latestVersion: expect.any(String),
          latestVersionCode: expect.any(Number),
          updateUrl: expect.any(String),
          title: expect.any(String),
          releaseNotes: expect.any(String),
          forceUpdate: expect.any(Boolean),
        }),
      })
    );
  });

  test('updates version information dynamically', async () => {
    req.body = {
      latestVersion: '2.0.0',
      latestVersionCode: 5,
      updateUrl: 'https://example.com/chindi-v2.apk',
      title: 'Major Update V2.0 🚀',
      releaseNotes: 'Redesigned experience and new features.',
      forceUpdate: true,
    };

    await updateAppVersion(req, res, next);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: true,
        data: expect.objectContaining({
          latestVersion: '2.0.0',
          latestVersionCode: 5,
          updateUrl: 'https://example.com/chindi-v2.apk',
          title: 'Major Update V2.0 🚀',
          forceUpdate: true,
        }),
      })
    );
  });
});
