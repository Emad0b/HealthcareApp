const express = require('express');
const bodyParser = require('body-parser');
const { sql, getConnection } = require('./dbConfig');

const app = express();
app.use(bodyParser.json());

// Endpoint to insert heart rate data
app.post('/api/heartRate', async (req, res) => {
  const { userID, heartRateData } = req.body;

  if (!userID || !heartRateData) {
    return res.status(400).json({ message: "UserID and heartRateData are required" });
  }

  try {
    const pool = await getConnection();
    const query = `
      INSERT INTO HeartRateReadings (UserID, HeartRateData)
      VALUES (@userID, @heartRateData)
    `;
    await pool.request()
      .input('userID', sql.Int, userID)
      .input('heartRateData', sql.NVarChar, heartRateData)
      .query(query);

    res.status(201).json({ message: "Heart rate data inserted successfully" });
  } catch (err) {
    console.error("Insert failed:", err); // Log the error details
    res.status(500).json({ message: "Error inserting heart rate data", error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
