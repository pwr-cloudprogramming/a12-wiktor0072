package com.javamaster.service;


import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.model.PutObjectRequest;
import com.amazonaws.services.s3.model.S3Object;
import com.amazonaws.services.s3.model.S3ObjectInputStream;
import com.javamaster.controller.GameController;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.web.ServerProperties;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.core.ResponseInputStream;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;

import java.io.*;

@Service
public class S3BucketService {

    @Autowired
    private AmazonS3 amazonS3;
    private static final Logger logger = LoggerFactory.getLogger(GameController.class);


    public boolean doesBucketExist(String bucketName) {
        return amazonS3.doesBucketExistV2(bucketName);
    }

    public void createBucket(String login) {
        amazonS3.createBucket(login);
    }

    public void uploadFile(String key, MultipartFile file, String bucketName ) throws IOException {
        PutObjectRequest putObjectRequest = new PutObjectRequest(bucketName, key, file.getInputStream(), null);
        amazonS3.putObject(putObjectRequest);
    }

    public Resource getFile(String bucketName, String fileName) throws IOException {

        S3Object s3Object = amazonS3.getObject(bucketName, fileName);
        var bytes = s3Object.getObjectContent().readAllBytes();
        Resource resource = new ByteArrayResource(bytes);
        return resource;

    }
}
