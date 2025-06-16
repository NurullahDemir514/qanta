-- Create RLS policies for profile-images storage bucket
-- This allows users to upload, view, update and delete their own profile images

-- Enable RLS on storage.objects table (should already be enabled)
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy: Users can upload their own profile images
CREATE POLICY "Users can upload their own profile images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can view their own profile images
CREATE POLICY "Users can view their own profile images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'profile-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can update their own profile images
CREATE POLICY "Users can update their own profile images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profile-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can delete their own profile images
CREATE POLICY "Users can delete their own profile images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profile-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Allow public access to profile images (for viewing)
-- This allows profile images to be viewed by anyone with the URL
CREATE POLICY "Public can view profile images" ON storage.objects
FOR SELECT USING (
  bucket_id = 'profile-images'
); 