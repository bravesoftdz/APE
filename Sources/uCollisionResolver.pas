unit uCollisionResolver;

interface

uses uAbstractParticle, uVector, uCollision, uMathUtil;

type

  { TCollisionResolver }

  TCollisionResolver = class
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure ResolveParticleParticle(pa, pb: TAbstractPArticle;
      normal: TVector; Depth: double);
  end;

var
  CollisionResolverInstance: TCollisionResolver;

implementation

uses uLogger;

{ TCollisionResolver }

constructor TCollisionResolver.Create;
begin
  LogAddObj(self);
end;

destructor TCollisionResolver.Destroy;
begin
  LogRemoveObj(self);
  inherited Destroy;
end;

procedure TCollisionResolver.ResolveParticleParticle(pa, pb: TAbstractPArticle;
  normal: TVector; Depth: double);
var
  mtd, vna, vnb, mtda, mtdb: TVector;
  te, suminvmass, tf: double;
  ca, cb: TCollision;
begin
  // a collision has occured. set the current positions to sample locations
  CopyVector(pa.Curr, pa.Samp^);
  CopyVector(pb.Curr, pb.Samp^);

  mtd := Mult(normal, depth);
  te  := pa.Elasticity + pb.Elasticity;
  suminvmass := pa.InvMass + pb.InvMass;

  // the total friction in a collision is combined but clamped to [0,1]
  tf := Clamp(1 - (pa.Friction + pb.Friction), 0, 1);

  // get the collision components, vn and vt
  ca := pa.GetComponents(normal);
  cb := pb.GetComponents(normal);

  // calculate the coefficient of restitution based on the mass, as the normal component
  vnA := DivVector(plus(mult(cb.vn^, (te + 1) * pa.invMass),
    mult(ca.vn^, pb.invMass - te * pa.invMass)), sumInvMass);
  vnB := DivVector(plus(mult(ca.vn^, (te + 1) * pb.invMass),
    mult(cb.vn^, pa.invMass - te * pb.invMass)), sumInvMass);

  // apply friction to the tangental component
  multEquals(ca.vt, tf);
  multEquals(cb.vt, tf);

  // scale the mtd by the ratio of the masses. heavier particles move less
  mtdA := mult(mtd, pa.invMass / sumInvMass);
  mtdB := mult(mtd, -pb.invMass / sumInvMass);

  // add the tangental component to the normal component for the new velocity
  plusEquals(@vnA, ca.vt^);
  plusEquals(@vnB, cb.vt^);

  if not pa.Fixed then
    pa.ResolveCollision(mtdA, vnA, normal, depth, -1, pb);
  if not pb.Fixed then
    pb.resolveCollision(mtdB, vnB, normal, depth, 1, pa);
end;

initialization
  CollisionResolverInstance := TCollisionResolver.Create;

finalization
  CollisionResolverInstance.Free;

end.

