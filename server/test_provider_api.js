const ServiceRequest = require('./models/ServiceRequest');
const providerController = require('./controllers/providerController');

// Mock ServiceRequest.find to return a fake document
ServiceRequest.find = async (filter) => {
  return [
    {
      toObject: () => ({
        _id: 'req1',
        serviceTaker: { _id: 't1', name: 'Alice', email: 'alice@example.com', phone: '9999999999' },
        address: '123 Main St',
        city: 'Metropolis',
        preferredDate: new Date('2026-06-12'),
        preferredTimeSlot: 'Morning',
        budgetLabel: 'Rs 500-1000',
        title: 'AC Repair',
        description: 'AC not cooling',
        imageUrl: 'http://example.com/img.jpg',
        issueImages: ['http://example.com/issue1.jpg'],
      }),
    },
  ];
};

// Mock req/res
const req = { user: { _id: 'provider1' } };
const res = {
  json(data) {
    console.log('--- response json ---');
    console.log(JSON.stringify(data, null, 2));
  },
  status(code) { this._status = code; return this; },
};

(async () => {
  try {
    await providerController.listAssignedRequests(req, res);
    console.log('Test finished');
  } catch (err) {
    console.error('Error running test:', err);
  }
})();
