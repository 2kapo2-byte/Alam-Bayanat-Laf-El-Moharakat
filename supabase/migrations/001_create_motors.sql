create extension if not exists pgcrypto;

create table if not exists public.motors (
  id uuid primary key default gen_random_uuid(),
  motor_code text not null unique,
  motor_type text not null,
  motor_power text not null,
  motor_speed text not null,
  winding_step text not null,
  wire_diameter text not null,
  coil_count integer not null check (coil_count > 0),
  welding_method text not null,
  connection_type text not null,
  technician_name text not null,
  created_at timestamptz not null default now()
);

create sequence if not exists public.motor_code_seq;

create or replace function public.set_motor_code()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.motor_code is null or btrim(new.motor_code) = '' then
    new.motor_code := 'MOTOR-' || lpad(nextval('public.motor_code_seq')::text, 4, '0');
  end if;
  return new;
end;
$$;

drop trigger if exists motors_set_code on public.motors;
create trigger motors_set_code before insert on public.motors for each row execute function public.set_motor_code();

create index if not exists idx_motors_type on public.motors(motor_type);
create index if not exists idx_motors_power on public.motors(motor_power);
create index if not exists idx_motors_speed on public.motors(motor_speed);
create index if not exists idx_motors_technician on public.motors(technician_name);
create index if not exists idx_motors_created_at on public.motors(created_at desc);

alter table public.motors enable row level security;
create policy "motors_read_authenticated" on public.motors for select to authenticated using (true);
create policy "motors_insert_authenticated" on public.motors for insert to authenticated with check (true);
