import React, { useEffect, useState } from 'react';
import axios from 'axios';
import './ResultPage.css'; 

const url = 'http://localhost:8080';

const ResultsPage = () => {
  const [results, setResults] = useState([]);

  useEffect(() => {
    const fetchResults = async () => {
      try {
        const response = await axios.get('http://localhost:8080/game/results');
        setResults(response.data);
      } catch (error) {
        console.error('Error fetching results:', error);
      }
    };

    fetchResults();
  }, []);

  return (
    <div>
      <h1>Game Results</h1>
      {results.length > 0 ? (
        <table>
          <thead>
            <tr>
              <th>Player 1</th>
              <th>Player 2</th>
              <th>Winner</th>
              <th>Player 1 Points</th>
              <th>Player 2 Points</th>
            </tr>
          </thead>
          <tbody>
            {results.map((result) => (
              <tr key={result.gameId} id='results'>
                <td>{result.player1}</td>
                <td>{result.player2}</td>
                <td>{result.winner}</td>
                <td>{result.player1Points}</td>
                <td>{result.player2Points}</td>
              </tr>
            ))}
          </tbody>
        </table>
      ) : (
        <p>No results found.</p>
      )}
    </div>
  );
};

export default ResultsPage;