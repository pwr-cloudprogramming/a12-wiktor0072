import React, { useState } from 'react';
import { useLocation } from 'react-router-dom';
import axios from './axiosConfig.js';

const UploadPage = () => {
  const location = useLocation();
  const email = location.state?.email;
  console.log(email)
  
  // Odbieranie login z state

  const [selectedFile, setSelectedFile] = useState(null);

  const onFileChange = (event) => {
    setSelectedFile(event.target.files[0]);
  };

  const onFileUpload = () => {
    const formData = new FormData();
    formData.append('file', selectedFile, selectedFile.name);
    formData.append('login', email);  // Dodawanie login do formData

    axios.post('http://localhost:8080/game/upload', formData)
      .then(response => {
        console.log(response.data);
      })
      .catch(error => {
        console.error('There was an error uploading the file!', error);
      });
  };

  const fileData = () => {
    if (selectedFile) {
      return (
        <div>
          <h2>File Details:</h2>
          <p>File Name: {selectedFile.name}</p>
          <p>File Type: {selectedFile.type}</p>
          <p>Last Modified: {selectedFile.lastModifiedDate.toDateString()}</p>
        </div>
      );
    } else {
      return (
        <div>
          <br />
          <h4>Choose before Pressing the Upload button</h4>
        </div>
      );
    }
  };

  return (
    <div>
      <h1>File Upload using React!</h1>
      <h3>Upload your file and login!</h3>
      <div>
        <input type="file" onChange={onFileChange} />
        <button onClick={onFileUpload}>
          Upload!
        </button>
      </div>
      {fileData()}
    </div>
  );
};

export default UploadPage;