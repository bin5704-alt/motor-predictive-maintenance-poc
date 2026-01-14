-- 1. Create Profiles Table (Simplified)
-- Removes user_role enum and role column.
CREATE TABLE public.profiles (
  id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email text,
  full_name text,
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Create Policies
-- Allow users to view key details of their own profile.
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Allow users to update their own profile.
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- 4. Create Trigger Function for New Users
-- Automatically creates a profile entry when a user signs up.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$;

-- 5. Attach Trigger
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 6. Grant Access
GRANT ALL ON TABLE public.profiles TO authenticated;
GRANT SELECT ON TABLE public.profiles TO anon;

-- [EMERGENCY RECOVERY PHASE 2]
-- 10. Re-create Raw Sensor Data Table (Corrected Schema)
DROP TABLE IF EXISTS public.raw_sensor_data;
CREATE TABLE public.raw_sensor_data (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id), -- Linked to user
  start_time timestamptz not null,
  sampling_rate int not null,
  samples float8[] not null, -- Array of sensor values
  created_at timestamptz default now()
);

-- 11. Security Policies
ALTER TABLE public.raw_sensor_data ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert own data" ON public.raw_sensor_data FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own data" ON public.raw_sensor_data FOR SELECT USING (auth.uid() = user_id);


-- [PHASE 3] HISTORY & ASSET MANAGEMENT
-- 12. Create Diagnosis Logs Table
CREATE TABLE IF NOT EXISTS public.diagnosis_logs (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) not null,
  score float8 not null,
  status text not null, -- 'Normal', 'Caution', 'Danger'
  metrics jsonb, -- {rms, peak, freq}
  prescription jsonb, -- {title, description}
  raw_data_id bigint references public.raw_sensor_data(id), -- Optional link to raw waveform
  created_at timestamptz default now()
);

-- 13. Create Maintenance Logs Table
CREATE TABLE IF NOT EXISTS public.maintenance_logs (
  id bigint generated always as identity primary key,
  diagnosis_id bigint references public.diagnosis_logs(id) on delete cascade not null,
  action_taken text not null,
  parts_replaced text,
  cost numeric default 0,
  technician text,
  created_at timestamptz default now()
);

-- 14. Enable RLS for New Tables
ALTER TABLE public.diagnosis_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_logs ENABLE ROW LEVEL SECURITY;

-- 15. RLS Policies
-- Diagnosis Logs
CREATE POLICY "Users can insert own diagnosis" ON public.diagnosis_logs FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can view own diagnosis" ON public.diagnosis_logs FOR SELECT USING (auth.uid() = user_id);

-- Maintenance Logs (Indirect access control via diagnosis linkage would be better, but for POC simplified)
-- Assuming maintenance logs are created by the same user or authorized personnel.
-- For simple POC, allow Authenticated users to select/insert.
CREATE POLICY "Auth users can manage maintenance" ON public.maintenance_logs FOR ALL USING (auth.role() = 'authenticated');


-- [PHASE 4] ASSET REGISTRATION
-- 16. Create Assets Table
CREATE TABLE IF NOT EXISTS public.assets (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) not null,
  name text not null,
  type text not null, -- e.g., 'Induction Motor'
  image_url text, -- Optional photo of the equipment
  specifications jsonb, -- {rpm, voltage, bearings: {de, nde}}
  created_at timestamptz default now()
);

-- 17. Enable RLS for Assets
ALTER TABLE public.assets ENABLE ROW LEVEL SECURITY;

-- 18. RLS Policies for Assets
CREATE POLICY "Users can insert own assets" ON public.assets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own assets" ON public.assets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own assets" ON public.assets FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own assets" ON public.assets FOR DELETE USING (auth.uid() = user_id);
