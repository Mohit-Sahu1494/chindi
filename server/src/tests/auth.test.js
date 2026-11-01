const bcrypt = require('bcryptjs');
const User = require('../models/User');
const { login, signup, signupSchema, loginSchema } = require('../controllers/authController');

jest.mock('../models/User');
jest.mock('bcryptjs');

describe('Auth Controller Error Handling', () => {
  let req, res, next;

  beforeEach(() => {
    jest.clearAllMocks();
    req = {
      body: {},
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    next = jest.fn();
  });

  describe('login error handling', () => {
    test('returns 404 with "Email not found" when user is not found', async () => {
      req.body = {
        emailOrMobile: 'notfound@example.com',
        password: 'password123',
      };
      User.findOne.mockResolvedValue(null);

      await login(req, res, next);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Email not found',
        })
      );
    });

    test('returns 401 with "Email and password is incorrect" when password does not match', async () => {
      req.body = {
        emailOrMobile: 'existing@example.com',
        password: 'wrongpassword',
      };
      User.findOne.mockResolvedValue({
        _id: 'user123',
        emailOrMobile: 'existing@example.com',
        passwordHash: 'hash123',
      });
      bcrypt.compare.mockResolvedValue(false);

      await login(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Email and password is incorrect',
        })
      );
    });
  });

  describe('signup error handling', () => {
    test('returns 409 when user with email already exists', async () => {
      req.body = {
        name: 'Test User',
        emailOrMobile: 'existing@example.com',
        password: 'password123',
      };
      User.findOne.mockResolvedValue({
        _id: 'user123',
        emailOrMobile: 'existing@example.com',
      });

      await signup(req, res, next);

      expect(res.status).toHaveBeenCalledWith(409);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'User with this email or mobile already exists',
        })
      );
    });
  });

  describe('validation schema error messages', () => {
    test('signupSchema fails on short password with clear message', () => {
      const result = signupSchema.safeParse({
        name: 'Test',
        emailOrMobile: 'test@example.com',
        password: '123',
      });
      expect(result.success).toBe(false);
      expect(result.error.errors[0].message).toBe('Password must be at least 6 characters');
    });

    test('loginSchema fails on empty password with clear message', () => {
      const result = loginSchema.safeParse({
        emailOrMobile: 'test@example.com',
        password: '',
      });
      expect(result.success).toBe(false);
      expect(result.error.errors[0].message).toBe('Password is required');
    });
  });
});
