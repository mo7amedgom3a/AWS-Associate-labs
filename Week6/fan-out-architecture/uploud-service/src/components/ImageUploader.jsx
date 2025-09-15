import { useState } from 'react';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

const ImageUploader = () => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [message, setMessage] = useState('');

  const handleFileChange = (event) => {
    setSelectedFile(event.target.files[0]);
    setMessage('');
  };

  const handleUpload = async () => {
    if (!selectedFile) {
      setMessage('Please select a file first.');
      return;
    }

    setUploading(true);
    setMessage('Uploading...');

    const s3Client = new S3Client({
      region: 'us-east-1', // Replace with your bucket's region
      // Credentials will be automatically picked up from the EC2 instance profile
    });

    try {
      const fileBuffer = await selectedFile.arrayBuffer();

      const params = {
        Bucket: 'fanout-image-upload-bucket-131eb674',
        Key: selectedFile.name,
        Body: fileBuffer,
        ContentType: selectedFile.type,
      };

      const command = new PutObjectCommand(params);
      await s3Client.send(command);
      setMessage('Image uploaded successfully!');
    } catch (error) {
      console.error('Error uploading image:', error);
      setMessage('Error uploading image. Please check the console for details.');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div>
      <h2>Upload Image to S3</h2>
      <input type="file" accept="image/*" onChange={handleFileChange} />
      <button onClick={handleUpload} disabled={uploading}>
        {uploading ? 'Uploading...' : 'Upload'}
      </button>
      {message && <p>{message}</p>}
    </div>
  );
};

export default ImageUploader;
