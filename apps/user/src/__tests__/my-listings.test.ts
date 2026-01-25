/**
 * @jest-environment node
 */

// Simple test to verify the my-listings API returns the correct format
describe('My Listings API', () => {
  const API_URL = 'http://localhost:3000/api/v1';
  let userToken: string;

  beforeAll(async () => {
    // Get a token for a test user
    const sendOtpRes = await fetch(`${API_URL}/auth/send-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone: '+256780050180' }),
    });
    expect(sendOtpRes.ok).toBe(true);

    const verifyRes = await fetch(`${API_URL}/auth/verify-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone: '+256780050180', code: '123456' }),
    });
    expect(verifyRes.ok).toBe(true);

    const authData = await verifyRes.json();
    userToken = authData.accessToken;
    expect(userToken).toBeDefined();
  });

  test('GET /listings/my returns paginated response with data array', async () => {
    const res = await fetch(`${API_URL}/listings/my`, {
      headers: { Authorization: `Bearer ${userToken}` },
    });

    expect(res.ok).toBe(true);
    const data = await res.json();

    // Verify paginated response structure
    expect(data).toHaveProperty('data');
    expect(data).toHaveProperty('total');
    expect(data).toHaveProperty('page');
    expect(data).toHaveProperty('limit');
    expect(data).toHaveProperty('totalPages');

    // data should be an array
    expect(Array.isArray(data.data)).toBe(true);

    // If there are listings, verify structure
    if (data.data.length > 0) {
      const listing = data.data[0];
      expect(listing).toHaveProperty('id');
      expect(listing).toHaveProperty('title');
      expect(listing).toHaveProperty('price');
      expect(listing).toHaveProperty('status');
    }
  });

  test('GET /listings/my requires authentication', async () => {
    const res = await fetch(`${API_URL}/listings/my`);

    expect(res.status).toBe(401);
  });
});
